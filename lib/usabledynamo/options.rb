module UsableDynamo
  class Options
    attr_reader :conditions

    def initialize(conditions = {})
      @conditions = conditions
    end

    def matched?(record)
      self.persistence_matched?(record) && self.conditions_matched?(record)
    end

    def persistence_matched?(record)
      @conditions[:on].nil? || @conditions[:on].to_s == "save" ||
        (@conditions[:on].to_s == "create" && ! record.persisted?) ||
        (@conditions[:on].to_s == "update" && record.persisted?)      
    end

    def conditions_matched?(record)
      (@conditions[:if].nil? || execute_conditions(record, @conditions[:if])) &&
      (@conditions[:unless].nil? || ! execute_conditions(record, @conditions[:unless]))
    end

    private

    def execute_conditions(record, condition)
      if condition.is_a?(Proc)
        condition.call(record)
      else
        record.send(condition)
      end
    end
  end
end

