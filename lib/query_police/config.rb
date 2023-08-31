# frozen_string_literal: true

require_relative "constants"

module QueryPolice
  # This class is used for configuration of query police
  class Config
    def initialize
      @analysis_footer = Constants::DEFAULT_ANALYSIS_FOOTER
      @logger_enabled = Constants::DEFAULT_LOGGER_ENABLED
      @logger_options = Constants::DEFAULT_LOGGER_OPTIONS
      @rules_path = Constants::DEFAULT_RULES_PATH
      @verbosity = Constants::DEFAULT_VERBOSITY
    end

    def logger_enabled?
      @logger_enabled.present?
    end

    attr_accessor :analysis_footer, :logger_enabled, :logger_options, :rules_path, :verbosity
  end
end
