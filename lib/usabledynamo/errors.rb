module UsableDynamo
  class Errors
    attr_reader :base, :messages

    def initialize(base)
      @base = base
      @messages = {}
    end

    def add(column_name, message)
      name = column_name.to_sym
      @messages[name] ||= []
      @messages[name] << message
    end

    def [](column_name)
      @messages[column_name.to_sym]
    end

    def blank?
      @messages.blank?
    end
    alias_method :empty?, :blank?

    def clear
      @messages = {}
    end

    def full_messages
      @messages.inject([]) do |result, (key, values)|
        name = key.to_s.humanize        # Just simple translation for now.
        values.each { |msg| result << "#{name} #{msg}" }
        result
      end
    end
  end
end

