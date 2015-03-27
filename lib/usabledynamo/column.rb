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
        # String needs extra checking to convert to correct type.
        val = string_to_real(val) if val.is_a?(String)
        val = real_to_native(val)
        # No more binary data type in v2?
        # native_type[0] == "b" ? Aws::DynamoDB::Binary.new(val) : val.to_s
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
          value == "true" || value.to_i == 1
          # %w(true 1).include?(value)
        when "date"
          Time.at(value.to_i).utc.to_date
        when "datetime"
          Time.at(value.to_i).utc.to_datetime
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

    def string_to_real(val)
      if type =~ /^date/
        DateTime.parse(val)
      elsif type == "boolean"
        %w(true 1).include?(val)
      else
        val
      end
    end

    def real_to_native(val)
      case val
        when Date, DateTime, Time
          val.to_i
        when TrueClass
          1
        when FalseClass
          0
        else
          val
        end
    end
  end
end
