module UsableDynamo
  module ClientMethods
    module Validation
      def validates(*args)
        # Not sure if we need this for now.
      end

      def validates_presence_of(*args)
        cols, opts = parse_validation(*args)
        cols.each do |col|
          column = column_for(col)
          raise "Validation error: column '#{col}' not found" if column.nil?
          @@validations << UsableDynamo::Validation.new(column, :presence, opts)
        end
      end

      private

      def parse_validation(*args)
        columns, options = [], {}
        args.each do |arg|
          if arg.is_a?(Hash)
            options.merge!(arg)
          else
            columns << arg.to_s
          end
        end
        [columns, options]
      end
    end
  end
end

