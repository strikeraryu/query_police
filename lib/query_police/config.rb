# frozen_string_literal: true

require_relative "constants"

module QueryPolice
  # This class is used for configuration of query police
  class Config
    def initialize
      @action_enabled = Constants::DEFAULT_ACTION_ENABLED
      @analysis_footer = Constants::DEFAULT_ANALYSIS_FOOTER
      @logger_options = Constants::DEFAULT_LOGGER_OPTIONS
      @rules_path = Constants::DEFAULT_RULES_PATH
      @verbosity = Constants::DEFAULT_VERBOSITY
    end

    def action_enabled?
      @action_enabled.present?
    end

    attr_accessor :action_enabled, :analysis_footer, :logger_options, :rules_path, :verbosity
  end
end
