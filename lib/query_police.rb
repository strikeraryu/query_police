# frozen_string_literal: true

require "active_record"
require "active_support/notifications"
require "active_support/core_ext"
require "json"
require "forwardable"

require_relative "query_police/analysis"
require_relative "query_police/constants"
require_relative "query_police/config"
require_relative "query_police/explain"
require_relative "query_police/helper"
require_relative "query_police/version"

# This module provides tools to analyse your queries based on custom rules
module QueryPolice
  extend Forwardable

  class Error < StandardError; end

  @config = Config.new(
    Constants::DEFAULT_DETAILED, Constants::DEFAULT_RULES_PATH
  )

  CONFIG_METHODS = %i[
    detailed detailed? detailed= rules_path rules_path=
  ].freeze

  def_delegators :config, *CONFIG_METHODS

  # to create analysis for ActiveRecord::Relation or a query string
  # @param relation [ActiveRecord::Relation, String]
  # @return [QueryPolice::Analysis] analysis - contains the analysis of the query
  def analyse(relation)
    rules_config = Helper.load_config(config.rules_path)
    analysis = Analysis.new
    summary = {}

    query_plan = Explain.full_explain(relation, config.detailed?)

    query_plan.each do |table|
      table_analysis, summary = analyse_table(table, summary, rules_config)

      analysis.register_table(table.dig("table"), table_analysis)
    end

    analysis.register_summary(generate_summary_analysis(rules_config, summary))

    analysis
  end

  # to add a logger to print analysis after each query
  # @param silent [Boolean] silent errors for logger
  # @param logger_config [Hash] possible options [positive: <boolean>, negative: <boolean>, caution: <boolean>]
  def subscribe_logger(silent: false, logger_config: Constants::DEFAULT_LOGGER_CONFIG)
    ActiveSupport::Notifications.subscribe("sql.active_record") do |_, _, _, _, payload|
      begin
        if !payload[:exception].present? && payload[:name] =~ /.* Load/
          analysis = analyse(payload[:sql])

          Helper.logger(analysis.pretty_analysis(logger_config))
        end
      rescue StandardError => e
        raise e unless silent.present?

        Helper.logger("#{e.class}: #{e.message}", "error")
      end
    end
  end

  class << self
    attr_accessor :config

    private

    def add_summary(summary, column_name, value)
      summary["cardinality"] = (summary.dig("cardinality") || 1) + value.to_f if column_name.eql?("rows")

      summary
    end

    def analyse_table(table, summary, rules_config)
      table_analysis = {}

      table.each do |column, value|
        summary = add_summary(summary, column, value)
        next unless rules_config.dig(column).present?

        table_analysis.merge!({ column => apply_rules(rules_config.dig(column), value) })
      end

      [table_analysis, summary]
    end

    def apply_rules(column_rules, value)
      column_rules = Constants::DEFAULT_COLUMN_RULES.merge(column_rules)
      value = transform_value(value, column_rules)
      amount = transform_amount(value, column_rules)

      column_analyse = { "value" => value, "amount" => amount, "tags" => {} }

      [*value].each do |tag|
        tag_rule = column_rules.dig("rules", tag)
        next unless tag_rule.present?

        column_analyse["tags"].merge!({ tag => transform_tag_rule(tag_rule) })
      end

      column_analyse["tags"].merge!(apply_threshold_rule(column_rules, amount))

      column_analyse
    end

    def apply_threshold_rule(column_rules, amount)
      threshold_rule = column_rules.dig("rules", "threshold")

      if threshold_rule.present? && amount >= threshold_rule.dig("amount")
        return {
          "threshold" => transform_tag_rule(threshold_rule).merge(
            { "amount" => amount }
          )
        }
      end

      {}
    end

    def generate_summary_analysis(rules_config, summary)
      summary_analysis = {}

      summary.each do |column, value|
        next unless rules_config.dig(column).present?

        summary_analysis.merge!({ column => apply_rules(rules_config.dig(column), value) })
      end

      summary_analysis
    end

    def transform_amount(value, column_rules)
      column_rules.dig("value_type").eql?("number") ? value.to_f : value.size
    end

    def transform_tag_rule(tag_rule)
      tag_rule.slice("impact", "suggestion", "message")
    end

    def transform_value(value, column_rules)
      value ||= "absent"

      if column_rules.dig("value_type").eql?("array") && column_rules.dig("delimiter").present?
        value = value.split(column_rules.dig("delimiter")).map(&:strip)
      end

      value
    end
  end

  module_function :analyse, :subscribe_logger, *CONFIG_METHODS
end
