module UsableDynamo
  module Document
    class RecordNotSaved < StandardError; end

    module ClassMethods
      attr_reader    :attributes, :persisted
      attr_accessor  :errors

      # Record manipulation methods.
      def create(attrs = {})
        self.new(attrs).tap { |rec| rec.save }
      end

      def create!(attrs = {})
        self.new(attrs).tap { |rec| rec.save! }
      end

      # Miscellaneous methods.
      def log_info(method, opts)
        if defined?(Rails)
          Rails.logger.info "Performing '#{method}' on dynamodb table '#{self.table_name}' with the following options:"
          Rails.logger.info opts.inspect
        end
      end
    end

    module InstanceMethods
      def initialize(attrs = {})
        @errors    = UsableDynamo::Errors.new(self)
        @persisted = false
        # Create table if not exists.
        #self.class.create_table unless self.class.table_exists?
        # super(attrs)
        default_attrs = self.class.column_names.inject(Hash.new("id" => nil)) do |result, col|
          result[col.to_s] = nil
          result
        end
        @attributes = attrs.stringify_keys.reverse_merge(default_attrs)
        @attributes.keys.each do |attr|
          define_singleton_method attr, lambda { @attributes[attr] }
          define_singleton_method "#{attr}=", lambda { |value| @attributes[attr] = value }
        end
      end

      def attributes
        @attributes   # Why do we need this?
      end

      def attributes=(attrs = {})
        @attributes.merge!(attrs.stringify_keys)
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
        self.class.callbacks[:before_validation].to_a.each do |callback|
          next unless callback.persistence_matched?(self)
          callback.apply(self)
        end
        self.class.validations.each do |validation|
          validation.validator.valid?(self)
        end
        self.errors.blank?.tap do |result|
          self.class.callbacks[:after_validation].to_a.each do |callback|
            next unless callback.persistence_matched?(self)
            callback.apply(self)
          end if result
        end
      end

      def save(options = {})
        if (options[:validate] == false || self.valid?) &&
           execute_before_save_callbacks(@persisted)
          attrs = attributes_to_save
          opts = {
            table_name: self.class.table_name,
            item: attrs,
            return_values: "ALL_OLD"
          }
          self.class.log_info(:put_item, opts)
          self.class.dynamodb_client.put_item(opts)
          write_attributes_from_native(attrs)
          old_persisted = @persisted
          (@persisted = true).tap do
            execute_after_save_callbacks(old_persisted)
          end
        else
          false
        end
      end

      def save!(options = {})
        save.tap do |result|
          raise UsableDynamo::Document::RecordNotSaved unless result
        end
      end

      def update_attributes(attrs = {})
        self.attributes = attrs
        self.save
      end

      def update_attributes!(attrs = {})
        self.attributes = attrs
        self.save!
      end

      def destroy
        if ! self.id.blank? && execute_before_destroy_callbacks
          @persisted = false
          id_column = self.class.column_for("id")
          keys = { "id" => { id_column.native_type => self.id.to_s } }
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
          execute_after_destroy_callbacks
        end
      end

      private

      def attributes_to_save
        attrs = self.class.columns.inject({}) do |result, column|
          # NOTE: attributes can't be empty, we only need to save existing value.
          value = self.attributes[column.name]
          # NOTE: Can't use .blank?, sometimes it's causing encoding issue.
          result[column.name.to_s] = { column.native_type => column.to_native(value) } unless value.nil? || value == ""
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
            conditions = self.class.column_exists?("created_at") ? { "created_at.ge" => 0 } : {}
            loop do
              value = SecureRandom.uuid
              conditions["id"] = value
              break unless self.class.find_by(conditions)
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

      def execute_before_save_callbacks(persisted)
        self.class.callbacks[:before_save].to_a.each do |callback|
          return false if callback.apply(self) == false
        end
        self.class.callbacks[:before_create].to_a.each do |callback|
          return false if callback.apply(self) == false
        end unless persisted
        self.class.callbacks[:before_update].to_a.each do |callback|
          return false if callback.apply(self) == false
        end if persisted
        true
      end

      def execute_after_save_callbacks(persisted)
        self.class.callbacks[:after_create].to_a.each do |callback|
          return false if callback.apply(self) == false
        end unless persisted
        self.class.callbacks[:after_update].to_a.each do |callback|
          return false if callback.apply(self) == false
        end if persisted
        self.class.callbacks[:after_save].to_a.each do |callback|
          return false if callback.apply(self) == false
        end
        true
      end

      def execute_before_destroy_callbacks
        self.class.callbacks[:before_destroy].to_a.each do |callback|
          return false if callback.apply(self) == false
        end
        true
      end

      def execute_after_destroy_callbacks
        self.class.callbacks[:after_destroy].to_a.each do |callback|
          return false if callback.apply(self) == false
        end
        true
      end
    end

    def self.included(klass)
      klass.extend ClassMethods
      klass.extend UsableDynamo::ClientMethods::Column
      klass.extend UsableDynamo::ClientMethods::Index
      klass.extend UsableDynamo::ClientMethods::Validation
      klass.extend UsableDynamo::ClientMethods::Table
      klass.extend UsableDynamo::ClientMethods::Finder
      klass.extend UsableDynamo::ClientMethods::Callback

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
      klass.cattr_accessor :before_validations
      # Document.
      klass.cattr_accessor :dynamodb_client
      klass.cattr_accessor :callbacks

      # Define the client on runtime to get the correct config.
      klass.dynamodb_client = AWS::DynamoDB::Client.new
      # Initial table name.
      klass.table_name ||= klass.to_s.tableize.parameterize.underscore

      klass.indexes = []
      klass.columns = []
      klass.validations = []
      klass.before_validations = []
      klass.attribute_definitions = []
      klass.callbacks = {}

      klass.module_eval do
        include InstanceMethods
      end
    end
  end
end
