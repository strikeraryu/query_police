# frozen_string_literal: true

# QueryPolice::Helper
module QueryPolice
  # This module define helper methods for query police
  module Helper
    DEFAULT_WORD_WRAP_WIDTH = 100

    def app_file_trace(app_dir)
      caller.select { |v| v =~ %r{#{app_dir}/} }
    end

    def colorize(string, colour)
      return string unless String.colors.include?(colour&.to_sym)

      string.send(colour)
    end

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

      case File.extname(rules_path)
      when ".yaml", ".yml"
        YAML.safe_load(File.read(rules_path))
      when ".json"
        JSON.parse(File.read(rules_path))
      else
        raise Error, "'#{File.extname(rules_path)}' extension is not supported for rules."
      end
    end

    def word_wrap(string, width: DEFAULT_WORD_WRAP_WIDTH, cut: false)
      width ||= DEFAULT_WORD_WRAP_WIDTH
      words = string.split
      wrapped_string = ""

      words.each do |word|
        last_line_size = (wrapped_string.split("\n")[-1]&.size || 0)
        if (last_line_size + word.size) > width
          return wrapped_string.strip + "..." if cut.present?

          wrapped_string = wrapped_string.strip + "\n"
        end
        wrapped_string += "#{word} "
      end

      wrapped_string.strip
    end

    module_function :app_file_trace, :colorize, :flatten_hash, :logger, :load_config, :word_wrap
  end

  private_constant :Helper
end
