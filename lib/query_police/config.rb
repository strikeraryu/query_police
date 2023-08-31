# frozen_string_literal: true

require_relative "constants"

module QueryPolice
  # This class is used for configuration of query police
  class Config
    def initialize
      @analysis_logger_enabled = Constants::DEFAULT_ANALYSIS_LOGGER_ENABLED
      @detailed = Constants::DEFAULT_DETAILED
      @logger_options = Constants::DEFAULT_LOGGER_OPTIONS
      @rules_path = Constants::DEFAULT_RULES_PATH
    end

    def analysis_logger_enabled?
      @analysis_logger_enabled.present?
    end

    def detailed?
      @detailed.present?
    end

    attr_accessor :analysis_logger_enabled, :detailed, :logger_options, :rules_path
  end
end
