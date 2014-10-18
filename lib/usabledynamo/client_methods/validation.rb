module UsableDynamo
  module ClientMethods
    module Validation
      def before_validation(method, options = {})
        add_callback(:before_validation, method, options)
      end

      def validates(*args)
        # Not sure if we need this for now.
      end

      def validate(*args)
        methods, opts = parse_validation(*args)
        methods.each do |method|
          validations << UsableDynamo::Validation.new(method, :method, opts)
        end
      end

      def validates_presence_of(*args)
        parse_and_assign_validations(:presence, *args)
      end

      def validates_uniqueness_of(*args)
        parse_and_assign_validations(:uniqueness, *args)
      end

      private

      def parse_and_assign_validations(type, *args)
        cols, opts = parse_validation(*args)
        cols.each do |col|
          column = column_for(col)
          raise "Validation error: column '#{col}' not found" if column.nil?
          validations << UsableDynamo::Validation.new(column, type, opts)
        end
      end

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

