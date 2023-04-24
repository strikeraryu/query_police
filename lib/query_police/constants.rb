# frozen_string_literal: true

module QueryPolice
  module Constants
    DEFAULT_COLUMN_RULES = {
      "value_type" => "string"
    }.freeze
    DEFAULT_DETAILED = true
    DEFAULT_LOGGER_CONFIG = {
      "negative" => true
    }.freeze
    DEFAULT_RULES_PATH =  File.join(File.dirname(__FILE__), "rules.json")
  end
end
