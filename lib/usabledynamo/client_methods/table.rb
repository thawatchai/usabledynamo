module UsableDynamo
  module ClientMethods
    module Table
      def set_shard_name(name)
        @@table_name = name
      end

      def create_table(read_capacity_units = 4, write_capacity_units = 4, options = {})
        key_schema = []
        hash = self.column_for("id")
        add_attribute_definition_with_schema(key_schema, "id", hash.native_type.upcase, "HASH")

        range = self.column_for("created_at")
        unless range.nil?
          add_attribute_definition_with_schema(key_schema, "created_at", range.native_type.upcase, "RANGE")
        end

        # NOTE: local_secondary_index is based on primary key(s), I guess
        # =>    we should always use global_secondary_index instead.

        global_secondary_indexes = []

        unless indexes.blank?
          indexes.each do |index|
            index_key_schema = []
            # DynamoDB only allows one hash and one range key max.
            if index.hash
              column = self.column_for(index.hash)
              add_attribute_definition_with_schema(index_key_schema, index.hash, column.native_type, "HASH")
            end
            if index.range
              column = self.column_for(index.range)
              add_attribute_definition_with_schema(index_key_schema, index.range, column.native_type, "RANGE")
            end
        
            global_secondary_indexes << {
              index_name: index.name,
              key_schema: index_key_schema,
              projection: { projection_type: "ALL" },
              provisioned_throughput: {
                read_capacity_units: read_capacity_units,
                write_capacity_units: write_capacity_units
              }
            }
          end
        end

        opts = {
          table_name: table_name,
          provisioned_throughput: {
            read_capacity_units: read_capacity_units,
            write_capacity_units: write_capacity_units
          },
          attribute_definitions: attribute_definitions,
          key_schema: key_schema
        }

        opts[:global_secondary_indexes] = global_secondary_indexes unless global_secondary_indexes.blank?

        log_info(:create_table, opts)
        dynamodb_client.create_table(opts)
      end

      def delete_table #(options = {})
        log_info(:delete_table, table_name: table_name)
        dynamodb_client.delete_table(table_name: table_name)
      end
      alias_method :drop_table, :delete_table

      def table_exists?
        @@table_exists ||
          begin
            log_info(:describe_table, table_name: table_name)
            dynamodb_client.describe_table(table_name: table_name)
            @@table_exists = true
          rescue AWS::DynamoDB::Errors::ResourceNotFoundException => e
            @@table_exists = false
          end
      end

      def list_tables(options = {})
        log_info(:list_tables, {})
        dynamodb_client.list_tables(options)
      end

      private

      def add_attribute_definition_with_schema(schema, name, type, index_type)
        name = name.to_s
        type = type.to_s.upcase
        index_type = index_type.to_s.upcase
        unless attribute_definitions.detect { |a| a[:attribute_name] == name }
          attribute_definitions << { attribute_name: name, attribute_type: type }
        end
        schema << { attribute_name: name, key_type: index_type }
      end
    end
  end
end

