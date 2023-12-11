# frozen_string_literal: true

module QueryPolice
  module Constants
    DEFAULT_ANALYSIS_FOOTER = ""
    DEFAULT_COLUMN_RULES = {
      "value_type" => "string"
    }.freeze
    DEFAULT_ACTION_ENABLED = true
    DEFAULT_APP_DIR = "app"
    DEFAULT_DEBT_RANGES = [
      { "range" => (0...200), "message" => "Good Query", "colour" => "green" },
      { "range" => (200...500), "message" => "Potentially Bad Query", "colour" => "yellow" },
      { "range" => (500...nil), "message" => "Bad Query", "colour" => "red" }
    ].freeze
    DEFAULT_LOGGER_OPTIONS = {
      "negative" => true,
      "caution" => true
    }.freeze
    DEFAULT_RULES_PATH = File.join(File.dirname(__FILE__), "rules.json")
    DEFAULT_VERBOSITY = "detailed"
  end
end
