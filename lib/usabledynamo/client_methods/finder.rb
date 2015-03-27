module UsableDynamo
  module ClientMethods
    module Finder

      def find_by(conditions, options = {})
        finder(conditions, options.merge(limit: 1))[0]
      end

      def find_all_by(conditions, options = {})
        finder(conditions, options)
      end

      def all
        finder({})
      end

      def exists?(conditions, options = {})
        finder(conditions, options.merge(limit: 1)).present?
      end

      def find_or_initialize_by(conditions, options = {})
        finder(conditions, options.merge(limit: 1))[0] ||
          self.new(conditions)
      end

      def find_or_create_by(conditions, options = {})
        finder(conditions, options.merge(limit: 1))[0] ||
          self.create(conditions)
      end

      def count(conditions = {}, options = {})
        finder(conditions, options.merge(count: true))
      end

      def find_each(conditions = {}, options = {})
        if block_given?
          last_evaluated_key = nil
          opts = options.merge(result_set: true)
          loop do
            opts = opts.merge(exclusive_start_key: last_evaluated_key) unless last_evaluated_key.blank?
            result_set = finder(conditions, opts)
            preprocess_members(result_set[:items]).each { |x| yield x }
            break if last_evaluated_key == result_set[:last_evaluated_key] || result_set[:last_evaluated_key].blank?
            last_evaluated_key = result_set[:last_evaluated_key]
          end
        end
      end

      private

      # Input examples from rails console:
      #
      # ddb.scan table_name: "processed_activity_streams", limit: 2,
      #          scan_filter: {
      #           "user_id" => {
      #             "attribute_value_list" => [{"n" => "2165"}],
      #             "comparison_operator" => "EQ"
      #           },
      #           "action" => {
      #             "attribute_value_list" => [{"s" => "created"}],
      #             "comparison_operator" => "EQ"
      #           }
      #         },
      #         conditional_operator: "OR",
      #         attributes_to_get: ["user_id", "created_at"]
      #
      # Available comparison operators:
      #
      # EQ | NE | LE | LT | GE | GT | NOT_NULL | NULL | CONTAINS |
      # NOT_CONTAINS | BEGINS_WITH | IN | BETWEEN
      #
      # BETWEEN must have 2 values.
      # IN can have multiple values.
      #
      def finder(conditions, options = {})
        find_opts = { table_name: self.table_name }
        # NOTE: The limit only works correctly when the index keys are all specified.
        find_opts[:limit] = options[:limit] unless options[:limit].blank?
        find_opts[:exclusive_start_key] = options[:exclusive_start_key] unless options[:exclusive_start_key].blank?

        unless options[:select].blank?
          attrs = if options[:select].is_a?(Array)
            options[:select].map(&:strip)
          else
            options[:select].split(/\s*,\s*/)
          end
          find_opts[:attributes_to_get] = attrs
        end

        find_opts[:select] = if options[:count]
          "COUNT"
        elsif find_opts[:attributes_to_get].blank?
          "ALL_ATTRIBUTES"
        end

        unless options[:start_with].blank?
          find_opts[:exclusive_start_key] = options[:start_with].inject({}) do |result, (attr, value)|
            column = column_for(attr)
            result[column.name] = value
            result
          end
        end

        # NOTE: Detect and use secondary index when applicable.
        index = detect_index(conditions)

        result_set = if index.nil?
          # Use .scan method.
          find_opts[:scan_filter] = build_filter(conditions)

          if assign_pagination_info(:scan, find_opts, options)
            # NOTE: .scan method is using table scan and supposed to be much slower.
            log_info(:scan, find_opts)
            dynamodb_client.scan(find_opts)
          else
            { count: 0, items: [] }
          end
        else
          # Use .query method.
          find_opts[:index_name] = index.name unless index.name == "primary"

          find_opts[:scan_index_forward] =
            (options[:order].to_s.downcase !~ /^desc/) unless options[:order].blank?

          # Split the :key_conditions and :query_filter arrays.
          key_conditions, query_filter = conditions.partition do |key, value|
            [index.hash, index.range].include?(key.to_s.split(".")[0])
          end

          find_opts[:key_conditions] = build_filter(Hash[key_conditions]) unless key_conditions.blank?
          find_opts[:query_filter]   = build_filter(Hash[query_filter])   unless query_filter.blank?

          if assign_pagination_info(:query, find_opts, options)
            log_info(:query, find_opts)
            dynamodb_client.query(find_opts)
          else
            { count: 0, items: [] }
          end
        end

        if defined?(Rails)
          Rails.logger.info "Result:"
          Rails.logger.info result_set.inspect
        end

        if options[:count]
          result_set[:count]
        elsif options[:result_set]
          result_set
        else
          preprocess_members(result_set[:items])
        end
      end

      def initialize_from_native(attrs)
        # All returned records should be translated using this.
        self.new.tap { |obj| obj.send(:write_attributes_from_native, attrs) }
      end

      def detect_index(attrs)
        # Only range key can have operators other than EQ, so we need to
        # exclude it from hash key search.
      
        # Get applicable hash and range keys first.
        hash_keys  = attrs.keys.map(&:to_s).select { |k| k !~ /\./ || k =~ /\.eq/i }
                       .map { |k| k.split(".")[0] }.uniq
        range_keys = attrs.keys.map { |k| k.to_s.split(".")[0] }.uniq

        # Include primary index in the detection.
        keys = { hash: :id }
        keys[:range] = :created_at if self.column_exists?("created_at")
        primary = UsableDynamo::Index.new(columns: keys, name: "primary")

        # Get the first match for both keys.
        (self.indexes + [primary]).detect do |index|
          (! index.hash || hash_keys.include?(index.hash)) &&
            (! index.range || (range_keys - [index.hash]).include?(index.range))
        end
      end

      def build_filter(conditions)
        conditions.inject({}) do |result, (attr, value)|
          key, operator = attr.to_s.split('.')
          operator = operator ? operator.upcase : "EQ"

          col = self.column_for(key)

          natives = case operator
          when "BETWEEN"
            [col.to_native(value[0]),
             col.to_native(value[1])]
          when "IN"
            value.map { |val| col.to_native(val) }
          else
            [col.to_native(value)]
          end

          result[key] = {
            attribute_value_list: natives,
            comparison_operator: operator
          }
          result
        end
      end

      def assign_pagination_info(method, find_opts, options)
        page = options[:page].to_i
        if find_opts[:limit].blank? && page >= 1
          per_page = options[:per_page].to_i
          per_page = 30 if per_page < 1
          find_opts[:limit] = per_page
        end
        if page > 1
          # NOTE: There's no easy way to do pagination here, we have to
          # =>    scan the table for :last_evaluated_key.
          last_evaluated_key = nil
          2.upto(page) do |n|
            conditions = { select: "COUNT", limit: per_page }
            conditions[:exclusive_start_key] = last_evaluated_key unless last_evaluated_key.blank?
            result_set = dynamodb_client.send(method, find_opts.merge(conditions))
            Rails.logger.info "Pagination scan result:"
            Rails.logger.info result_set.inspect
            last_evaluated_key = result_set[:last_evaluated_key]
            break if last_evaluated_key.nil?
          end
          return false if last_evaluated_key.nil?
          find_opts[:exclusive_start_key] = last_evaluated_key
        end
        true
      end

      def preprocess_members(members)
        members.map do |native_attrs|
          initialize_from_native(native_attrs).tap do |rec|
            callbacks[:after_find].to_a.each { |callback| callback.apply(rec) }
            rec.instance_variable_set(:@persisted, true)
          end
        end
      end
    end
  end
end

