module UsableDynamo
  module Document
    module ClassMethods
      attr_reader    :attributes, :persisted
      attr_accessor  :errors

      #@@dynamodb_client       = AWS::DynamoDB::Client.new
      #@@after_find_callbacks  = []

      # NOTE: we can move these to different modules, but need to make them work first.

      # Record manipulation methods.
      def create(attrs = {})
        self.new(attrs).tap { |rec| rec.save }
      end

      # Callback methods, the simple way.
      def after_find(method, options = {})
        after_find_callbacks << method
      end
      
      # Miscellaneous methods.
      def log_info(method, opts)
        Rails.logger.info "Performing '#{method}' on dynamodb table '#{self.table_name}' with the following options:"
        Rails.logger.info opts.inspect
      end
    end

    module InstanceMethods
      def initialize(attrs = {})
        @errors    = UsableDynamo::Errors.new(self)
        @persisted = false
        # Create table if not exists.
        self.class.create_table unless self.class.table_exists?
        # super(attrs)
        default_attrs = self.class.column_names.inject(HashWithIndifferentAccess.new(id: nil)) do |result, col|
          result[col.to_sym] = nil
          result
        end
        @attributes = attrs.reverse_merge(default_attrs)
        @attributes.keys.each do |attr|
          define_singleton_method attr, lambda { @attributes[attr] }
          define_singleton_method "#{attr}=", lambda { |value| @attributes[attr] = value }
        end
      end

      def attributes
        @attributes   # Why do we need this?
      end

      def attributes=(attrs = {})
        @attributes.merge!(attrs)
      end

      def errors
        @errors   # this one too?
      end

      def persisted?
        !! @persisted
      end

      def new_record?
        ! self.persisted?
      end

      def valid?
        self.errors.clear
        self.class.validations.each do |validation|
          validation.validator.valid?(self)
        end
        self.errors.blank?
      end

      def save(options = {})
        if options[:validate] == false || self.valid?
          attrs = attributes_to_save
          opts = {
            table_name: self.class.table_name,
            item: attrs,
            return_values: "ALL_OLD"
          }
          self.class.log_info(:put_item, opts)
          self.class.dynamodb_client.put_item(opts)
          write_attributes_from_native(attrs)
          @persisted = true
        else
          false
        end
      end

      def save!(options = {})
        save.tap do |result|
          raise ActiveRecord::RecordNotSaved unless result
        end
      end

      def destroy
        unless self.id.blank?
          @persisted = false
          keys = { "id" => { "S" => self.id } }
          # We need to specify both keys if defined that way.
          if self.class.column_exists?("created_at")
            keys["created_at"] = { "N" => self.created_at.to_i.to_s }
          end

          opts = {
            table_name: self.class.table_name,
            key: keys
          }
          self.class.log_info(:delete_item, opts)
          self.class.dynamodb_client.delete_item(opts)
        end
      end

      private

      def attributes_to_save
        attrs = self.class.columns.inject({}) do |result, column|
          # NOTE: attributes can't be empty, we only need to save existing value.
          value = self.attributes[column.name]
          result[column.name.to_s] = { column.native_type => column.to_native(value) } unless value.blank?
          result
        end

        now = Time.now.to_i
        attrs["created_at"] = { "n" => now.to_s } if self.new_record? && self.class.column_exists?("created_at") && attrs["created_at"].nil?
        attrs["updated_at"] = { "n" => now.to_s } if self.class.column_exists?("updated_at") && attrs["updated_at"].nil?
        if self.new_record? && self.class.column_exists?("id") && attrs["id"].nil?
          # Only :id column can have :auto flag.
          col = self.class.column_for("id")
          if col.auto
            value = nil
            loop do
              value = SecureRandom.uuid
              break unless self.class.find_by(id: value, "created_at.ge" => DateTime.parse("2000-1-1"))
            end
            attrs["id"] = { "s" => value }
          end
        end
        attrs
      end

      def write_attributes_from_native(native_attrs)
        # [{"id"=>{:s=>"f2f01385-c157-4468-b660-0ae6a799732f"},
        #   "created_at"=>{:n=>"1408222345"}},
        #  {"id"=>{:s=>"b5926b25-d72a-4178-8c08-f9c72e2340ad"},
        #   "content_id"=>{:n=>"12"},
        #   "content_attributes"=>{:s=>"{\"foo\":\"bar\",\"mudd\":\"zapp\"}"},
        #   "action"=>{:s=>"create"}, "created_at"=>{:n=>"1408223935"},
        #   "user_id"=>{:n=>"1"}, "target_type"=>{:s=>"Course"},
        #   "content_type"=>{:s=>"Course::Assessment"}, "target_id"=>{:n=>"4"}},
        #  {"id"=>{:s=>"9e29b9be-ee38-4b83-9fc7-ac684e443a85"},
        #   "content_id"=>{:n=>"2"},
        #   "content_attributes"=>{:s=>"{\"a\":\"hello\",\"b\":\"dude\"}"},
        #   "action"=>{:s=>"update"},
        #   "created_at"=>{:n=>"1408223455"},
        #   "user_id"=>{:n=>"2165"}, "target_type"=>{:s=>"Course"},
        #   "content_type"=>{:s=>"Course::Assignment"}, "target_id"=>{:n=>"4"}}]
        @attributes = self.class.columns.inject({}) do |result, column|
          result[column.name] = unless native_attrs[column.name].nil?
            column.to_real(native_attrs[column.name].values[0])
          end
          result
        end
      end
    end

    def self.included(klass)
      klass.extend ClassMethods
      klass.extend UsableDynamo::ClientMethods::Column
      klass.extend UsableDynamo::ClientMethods::Index
      klass.extend UsableDynamo::ClientMethods::Validation
      klass.extend UsableDynamo::ClientMethods::Table
      klass.extend UsableDynamo::ClientMethods::Finder

      # NOTE: We need to define the cattrs here to prevent attributes
      # =>    sharing among classes.
      # Table.
      klass.cattr_accessor :table_name
      klass.cattr_accessor :attribute_definitions
      # Index.
      klass.cattr_accessor :indexes
      # Column.
      klass.cattr_accessor :columns
      # Validation.
      klass.cattr_accessor :validations
      # Document.
      klass.cattr_accessor :dynamodb_client
      klass.cattr_accessor :after_find_callbacks

      # Define the client on runtime to get the correct config.
      klass.dynamodb_client = AWS::DynamoDB::Client.new
      # Initial table name.
      klass.table_name ||= klass.to_s.tableize.parameterize.underscore

      klass.indexes = []
      klass.columns = []
      klass.validations = []
      klass.attribute_definitions = []
      klass.after_find_callbacks = []

      klass.module_eval do
        include InstanceMethods
      end
    end
  end
end
