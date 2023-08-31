# frozen_string_literal: true

module QueryPolice
  module Constants
    DEFAULT_ANALYSIS_LOGGER_ENABLED = true
    DEFAULT_COLUMN_RULES = {
      "value_type" => "string"
    }.freeze
    DEFAULT_DETAILED = true
    DEFAULT_LOGGER_OPTIONS = {
      "negative" => true
    }.freeze
    DEFAULT_RULES_PATH = File.join(File.dirname(__FILE__), "rules.json")
  end
end
