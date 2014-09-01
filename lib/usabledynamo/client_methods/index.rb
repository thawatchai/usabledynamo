module UsableDynamo
  module ClientMethods
    module Index
      cattr_reader :indexes

      @@indexes = []

      def index(cols, options = {})
        indexes << UsableDynamo::Index.new(options.merge(columns: cols))
      end
    end
  end
end

