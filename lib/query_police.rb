# frozen_string_literal: true

require "active_record"
require "active_support/notifications"
require "active_support/core_ext"
require "colorize"
require "forwardable"
require "json"
require "terminal-table"

require_relative "query_police/analyse"
require_relative "query_police/analysis"
require_relative "query_police/config"
require_relative "query_police/constants"
require_relative "query_police/explain"
require_relative "query_police/helper"
require_relative "query_police/transform"
require_relative "query_police/version"

# This module provides tools to analyse your queries based on custom rules
module QueryPolice
  extend Forwardable

  class Error < StandardError; end

  @config = Config.new

  CONFIG_METHODS = %i[
    analysis_footer analysis_footer=
    logger_enabled logger_enabled? logger_enabled=
    logger_options logger_options=
    rules_path rules_path=
    verbosity verbosity=
  ].freeze

  def_delegators :config, *CONFIG_METHODS

  # to create analysis for ActiveRecord::Relation or a query string
  # @param relation [ActiveRecord::Relation, String]
  # @return [QueryPolice::Analysis] analysis - contains the analysis of the query
  def analyse(relation)
    rules_config = Helper.load_config(config.rules_path)
    analysis = Analysis.new(footer: config.analysis_footer)
    summary = {}

    query_plan = Explain.full_explain(relation, config.verbosity)

    query_plan.each do |table|
      table_analysis, summary, table_score = Analyse.table(table, summary, rules_config)

      analysis.register_table(table.dig("table"), table_analysis, table_score)
    end

    analysis.register_summary(*Analyse.generate_summary(rules_config, summary))

    analysis
  end

  module_function :analyse, *CONFIG_METHODS

  class << self
    attr_accessor :config

    def configure
      yield(config)
    end

    def evade_inspection
      old_config_value = config.logger_enabled
      config.logger_enabled = false

      return_value = yield

      config.logger_enabled = old_config_value
      return_value
    end

    private

    # to analyse and log the analysis of a query
    # @param query [ActiveRecord::Relation, String]
    def analysis_logger(query)
      return unless config.logger_enabled?

      analysis = analyse(query)
      Helper.logger(analysis.pretty_analysis(config.logger_options))
    end

    # to add a logger to print analysis after each query
    def subscribe_logger
      ActiveSupport::Notifications.subscribe("sql.active_record") do |_, _, _, _, payload|
        begin
          analysis_logger(payload[:sql]) unless payload[:exception].present? || payload[:sql] =~ /^\s*EXPLAIN\b/i
        rescue StandardError => e
          Helper.logger("#{name}::#{e.class}: #{e.message}", "error")
        end
      end
    end
  end

  # subscribe logger on module usage
  subscribe_logger
end
