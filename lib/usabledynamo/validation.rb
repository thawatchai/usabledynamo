module UsableDynamo
  class Validation
    attr_reader :type, :validator

    def initialize(object, type, options = {})
      @type = type.to_s
      @validator = case @type
        when "presence"
          Presence.new(object, options)
        when "method"
          Method.new(object, options)
        when "uniqueness"
          Uniqueness.new(object, options)
        else
          raise "Validation type is not implemented yet."
        end
    end

    class Presence
      attr_reader :column, :options

      def initialize(column, options = {})
        @column  = column
        @options = UsableDynamo::Options.new(options)
      end

      def valid?(record)
        col_name = column.name.to_s
        value = record.attributes[col_name]
        if ! options.skip_blank?(value) && options.matched?(record)
          value.present?.tap do |result|
            record.errors.add(col_name, I18n.t("errors.messages.blank")) unless result
          end
        end
      end
    end

    class Uniqueness
      attr_reader :column, :options

      def initialize(column, options = {})
        @column  = column
        @options = UsableDynamo::Options.new(options)
      end

      def valid?(record)
        col_name = column.name.to_s
        value = record.attributes[col_name]
        if ! options.skip_blank?(value) && options.matched?(record)
          conditions = options.conditions[:range] || {}
          scope = options.conditions[:scope]
          conditions[scope.to_s] = record.attributes[scope.to_s] unless scope.nil?
          conditions[col_name] = record.attributes[col_name]

          results = record.class.find_all_by(conditions)

          if results.detect { |rec| rec.id != record.id }
            record.errors.add(col_name, I18n.t("errors.messages.taken"))
          end
        end
      end
    end

    class Method
      attr_reader :method, :options

      def initialize(method, options = {})
        @method  = method
        @options = UsableDynamo::Options.new(options)
      end

      def valid?(record)
        record.send(method) if options.matched?(record)
      end
    end
  end
end
