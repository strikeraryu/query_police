# frozen_string_literal: true

# QueryPolice::Transform
module QueryPolice
  # This module define transformer methods for query police
  module Transform
    def absent_value(column_rules)
      case column_rules.dig("value_type")
      when "array"
        column_rules.dig("delimiter").present? ? "" : []
      when "number"
        0
      else
        "absent"
      end
    end

    def amount(value, column_rules)
      column_rules.dig("value_type").eql?("number") ? value.to_f : value.size
    end

    def tag_rule(tag_rule)
      tag_rule.slice("impact", "suggestion", "message")
    end

    def value(value, column_rules)
      value ||= absent_value(column_rules)

      if column_rules.dig("value_type").eql?("array") && column_rules.dig("delimiter").present?
        value = value.split(column_rules.dig("delimiter")).map(&:strip)
      end

      value
    end

    module_function :absent_value, :amount, :tag_rule, :value
  end

  private_constant :Transform
end
