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
      table_analysis, summary, table_score = Analyse.table(table, summary, rules_config)

      analysis.register_table(table.dig("table"), table_analysis, table_score)
    end

    analysis.register_summary(*Analyse.generate_summary(rules_config, summary))

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

    def configure
      yield(config)
    end
  end

  module_function :analyse, :subscribe_logger, *CONFIG_METHODS
end
