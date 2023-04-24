# frozen_string_literal: true

module QueryPolice
  # This class is used for configuration of query police
  class Config
    def initialize(detailed, rules_path)
      @detailed = detailed
      @rules_path = rules_path
    end

    def detailed?
      @detailed.present?
    end

    attr_accessor :detailed, :rules_path
  end
end
