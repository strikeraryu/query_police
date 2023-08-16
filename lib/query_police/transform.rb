# frozen_string_literal: true

# QueryPolice::Transform
module QueryPolice
  # This module define transformer methods for query police
  module Transform
    def amount(value, column_rules)
      return 0 if value.eql?("absent")

      column_rules.dig("value_type").eql?("number") ? value.to_f : value.size
    end

    def tag_rule(tag_rule)
      tag_rule.slice("impact", "suggestion", "message")
    end

    def value(value, column_rules)
      return "absent" if value.nil?

      if column_rules.dig("value_type").eql?("array") && column_rules.dig("delimiter").present?
        value = value.split(column_rules.dig("delimiter")).map(&:strip)
      end

      value
    end

    module_function :amount, :tag_rule, :value
  end

  private_constant :Transform
end
