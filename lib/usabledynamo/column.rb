module UsableDynamo
  class Column
    attr_reader :name, :type, :native_type, :set, :auto

    def initialize(options = {})
      @name        = options[:name].to_s
      @type        = options[:type].to_s
      @set         = !! options[:set]
      @native_type = get_native_type(@type, @set)
      @auto        = !! options[:auto]
    end

    def to_native(value)
      values = value.is_a?(Array) ? value : [value]
      values = values.map do |val|
        val = DateTime.parse(val) if val.is_a?(String) && type =~ /^date/
        val = val.to_i if val.is_a?(Date) || val.is_a?(DateTime) || val.is_a?(Time)
        native_type[0] == "b" ? AWS::DynamoDB::Binary.new(val) : val.to_s
      end
      native_type.length > 1 ? values : values[0]
    end

    def to_real(values)
      values = [values] unless values.is_a?(Array)
      values = values.map do |value|
        # NOTE: Any value type conversion should be done here.
        case type
        when "integer"
          value.to_i
        when "float"
          value.to_f
        when "boolean"
          %w(true 1).include?(value)
        when "date"
          Time.at(value.to_i).to_date
        when "datetime"
          Time.at(value.to_i).to_datetime
        else
          value
        end
      end
      native_type.length > 1 ? values : values[0]
    end

    private

    def get_native_type(db_type, set)
      native = case db_type
        when "string"
          "s"
        when "binary"
          "b"
        else
          "n"
        end
      native += "s" if set
      native
    end
  end
end
