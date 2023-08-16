# frozen_string_literal: true

# QueryPolice::Analyse
module QueryPolice
  # This module define analyse methods for query police
  module Analyse
    def table(table, summary, rules_config)
      table_analysis = {}
      table_score = 0

      table.each do |column, value|
        summary = add_summary(summary, column, value)
        next unless rules_config.dig(column).present?

        table_analysis.merge!({ column => apply_rules(rules_config.dig(column), value) })
        table_score += table_analysis.dig(column, "tags").map { |_, tag| tag.dig("score") }.sum.to_f
      end

      [table_analysis, summary, table_score]
    end

    def generate_summary(rules_config, summary)
      summary_analysis = {}
      summary_score = 0

      summary.each do |column, value|
        next unless rules_config.dig(column).present?

        summary_analysis.merge!({ column => apply_rules(rules_config.dig(column), value) })
        summary_score += summary_analysis.dig(column, "tags").map { |_, tag| tag.dig("score") }.sum.to_f
      end

      [summary_analysis, summary_score]
    end

    class << self
      private

      def add_summary(summary, column_name, value)
        summary["cardinality"] = (summary.dig("cardinality") || 1) * value.to_f if column_name.eql?("rows")

        summary
      end

      def apply_rules(column_rules, value)
        column_rules = Constants::DEFAULT_COLUMN_RULES.merge(column_rules)
        value = Transform.value(value, column_rules)
        amount = Transform.amount(value, column_rules)

        column_analyse = { "value" => value, "amount" => amount, "tags" => {} }

        [*value].each do |tag|
          tag_rule = column_rules.dig("rules", tag)
          next unless tag_rule.present?

          column_analyse["tags"].merge!(
            { tag => Transform.tag_rule(tag_rule).merge!({ "score" => generate_score(tag_rule, amount) }) }
          )
        end

        column_analyse["tags"].merge!(apply_threshold_rule(column_rules, amount))

        column_analyse
      end

      def apply_threshold_rule(column_rules, amount)
        threshold_rule = column_rules.dig("rules", "threshold")

        if threshold_rule.present? && amount >= threshold_rule.dig("amount")
          return {
            "threshold" => Transform.tag_rule(threshold_rule).merge(
              { "amount" => amount, "score" => generate_score(threshold_rule, amount) }
            )
          }
        end

        {}
      end

      def generate_score(tag_rule, amount)
        score = tag_rule.dig("score", "value")

        case tag_rule.dig("score", "type").to_s
        when "base"
          score.to_f
        when "relative"
          amount.to_f * score.to_f
        when "treshold_relative"
          (amount - tag_rule.dig("amount")).to_f * score.to_f
        else
          0
        end
      end
    end

    module_function :table, :generate_summary
  end

  private_constant :Analyse
end
