module UsableDynamo
  class Index
    attr_reader :name, :columns, :hash, :range

    def initialize(options = {})
      @columns = options[:columns]
      if @columns.is_a?(Array)
        @hash  = @columns[0].try(:to_s)
        @range = @columns[1].try(:to_s)
      else
        @hash  = @columns[:hash].try(:to_s)
        @range = @columns[:range].try(:to_s)
        @columns = [@hash, @range].compact
      end
      @name = options[:name] ? options[:name].to_s : "index_on_#{@columns.compact.join('_')}"
    end
  end
end

