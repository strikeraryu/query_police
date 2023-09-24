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
  @actions = []

  CONFIG_METHODS = %i[
    action_enabled action_enabled? action_enabled=
    analysis_footer analysis_footer=
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
      table_analysis, summary, table_debt = Analyse.table(table, summary, rules_config)

      analysis.register_table(table.dig("table"), table_analysis, table_debt)
    end

    analysis.register_summary(*Analyse.generate_summary(rules_config, summary))

    analysis
  end

  module_function :analyse, *CONFIG_METHODS

  class << self
    attr_accessor :config

    def add_action(&block)
      @actions << block

      true
    end

    def configure
      yield(config)
    end

    def evade_actions
      old_config_value = config.action_enabled
      config.action_enabled = false

      return_value = yield

      config.action_enabled = old_config_value
      return_value
    end

    private

    # perform actions on the analysis of a query
    # @param query [ActiveRecord::Relation, String]
    def perform_actions(query)
      return unless config.action_enabled?

      analysis = analyse(query)
      Helper.logger(analysis.pretty_analysis(config.logger_options))

      @actions.each do |action|
        action.call(analysis)
      end
    end

    # to subscribe to active support notification to perform actions after each query
    def subscribe_action
      ActiveSupport::Notifications.subscribe("sql.active_record") do |_, _, _, _, payload|
        begin
          perform_actions(payload[:sql]) if !payload[:exception].present? && payload[:name] =~ /.* Load/
        rescue StandardError => e
          Helper.logger("#{name}::#{e.class}: #{e.message}", "error")
        end
      end
    end
  end

  # subscribe to active support notification on module usage
  subscribe_action
end
