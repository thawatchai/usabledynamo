module UsableDynamo
  class Callback
    attr_reader :method, :options

    def initialize(method, options = {})
      @method  = method
      @options = UsableDynamo::Options.new(options)
    end

    def apply(record)
      record.send(@method) if @options.conditions_matched?(record)
    end

    def persistence_matched?(record)
      @options.persistence_matched?(record)
    end
  end
end