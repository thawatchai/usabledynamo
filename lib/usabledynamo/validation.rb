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
        if @options.matched?(record)
          record.attributes[column.name.to_s].present?.tap do |result|
            record.errors.add(column.name.to_s, I18n.t("errors.messages.blank")) unless result
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
        if @options.matched?(record)
          col = record.class.column_for(@column)
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
        if @options.matched?(record)
          record.send(@method)
        end
      end
    end
  end
end
