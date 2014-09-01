module UsableDynamo
  module ClientMethods
    module Column
      cattr_reader :columns, :column_names

      @@columns = [UsableDynamo::Column.new(name: "id", type: "string", set: false)]

      def string_attr(name, options = {})
        columns << UsableDynamo::Column.new(name: name.to_s, type: "string", set: !! options[:set])
      end

      def integer_attr(name, options = {})
        columns << UsableDynamo::Column.new(name: name.to_s, type: "integer", set: !! options[:set])
      end

      def float_attr(name, options = {})
        columns << UsableDynamo::Column.new(name: name.to_s, type: "float", set: !! options[:set])
      end

      def boolean_attr(name, options = {})
        columns << UsableDynamo::Column.new(name: name.to_s, type: "boolean", set: !! options[:set])
      end

      def date_attr(name, options = {})
        columns << UsableDynamo::Column.new(name: name.to_s, type: "date", set: !! options[:set])
      end

      def datetime_attr(name, options = {})
        columns << UsableDynamo::Column.new(name: name.to_s, type: "datetime", set: !! options[:set])
      end

      def binary_attr(name, options = {})
        columns << UsableDynamo::Column.new(name: name.to_s, type: "binary", set: !! options[:set])
      end

      def timestamps
        datetime_attr(:created_at)
        datetime_attr(:updated_at)
      end

      def column_names
        @@column_names ||= columns.map { |c| c.name }
      end

      def column_for(name)
        name = name.to_s
        columns.detect { |col| col.name == name }
      end

      def column_exists?(name)
        self.column_names.include?(name.to_s)
      end
    end
  end
end
