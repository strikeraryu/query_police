# frozen_string_literal: true

module QueryPolice
  # This module define helper methods for query police
  module Helper
    def flatten_hash(hash, prefix_key = "")
      flat_hash = {}

      hash.each do |key, value|
        key = prefix_key.present? ? "#{prefix_key}##{key}" : key.to_s

        flat_hash.merge!(value.is_a?(Hash) ? flatten_hash(value, key) : { key => value })
      end

      flat_hash
    end

    def logger(message, type="info")
      if defined?(Rails) && Rails.logger
        Rails.logger.send(type, message)
      else
        puts "#{type.upcase}: #{message}"
      end
    end

    def load_config(rules_path)
      unless File.exists?(rules_path)
        raise Error.new(
          "Failed to load the rule file from '#{rules_path}'. " \
          "The file may be missing or there is a problem with the path. " \
          "Please ensure that the file exists and the path is correct."
        )
      end

      rules_config = JSON.parse(File.read(rules_path))

      rules_config
    end

    module_function :flatten_hash, :logger, :load_config
  end

  private_constant :Helper
end
