module UsableDynamo
  class Validation
    attr_reader :type, :validator

    def initialize(column, type, options = {})
      @type = type.to_sym
      @validator = case type.to_sym
        when :presence
          Presence.new(column, options)
        else
          raise "Validation type is not implemented yet."
        end
    end

    class Presence
      attr_reader :column, :options

      def initialize(column, options = {})
        @column  = column
        @options = options
      end

      def valid?(record)
        record.attributes[column.name].present?.tap do |result|
          record.errors.add(column.name.to_s, I18n.t("errors.messages.blank")) unless result
        end
      end
    end
  end
end
