# frozen_string_literal: true

# QueryPolice::Helper
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

    def logger(message, type = "info")
      if defined?(Rails) && Rails.logger
        Rails.logger.send(type, message)
      else
        puts "#{type.upcase}: #{message}"
      end
    end

    def load_config(rules_path)
      unless File.exist?(rules_path)
        raise Error, "Failed to load the rule file from '#{rules_path}'. " \
          "The file may be missing or there is a problem with the path. " \
          "Please ensure that the file exists and the path is correct."
      end

      JSON.parse(File.read(rules_path))
    end

    def word_wrap(string, width = 100)
      words = string.split
      wrapped_string = " "

      words.each do |word|
        last_line_size = (wrapped_string.split("\n")[-1]&.size || 0)
        wrapped_string = wrapped_string.strip + "\n" if (last_line_size + word.size) > width
        wrapped_string += "#{word} "
      end

      wrapped_string.strip
    end

    module_function :flatten_hash, :logger, :load_config, :word_wrap
  end

  private_constant :Helper
end
