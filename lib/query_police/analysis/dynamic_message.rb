# frozen_string_literal: true

module QueryPolice
  class Analysis
    # Module to define methods related to dynamic message
    module DynamicMessage
      private

      LISTED_VAR = %w[amount column impact table tag value].freeze

      # to pretty print the analysis with warnings and suggestions
      # @param opts [Hash] opts to get specifc dyanmic message
      # eg. {"table" => "users", "column" => "select_type", "tag" => "SIMPLE", "type" => "message"}
      # @return [String]
      def dynamic_message(opts)
        table, column, tag, type = opts.values_at("table", "column", "tag", "type")
        message = self.tables.dig(table, "analysis", column, "tags", tag, type) || ""

        variables = message.scan(/\$(\w+)/).uniq.map { |var| var[0] }
        variables.each do |var|
          value = dynamic_value_of(var, opts)

          message.gsub!(/\$#{var}/, value.to_s) if value.present?
        end

        message
      end

      def dynamic_value_of(var, opts)
        LISTED_VAR.include?(var) ? send(var, opts) : relative_value_of(var, opts.dig("table"))
      end

      def relative_value_of(var, table)
        value_type = var.match(/amount_/).present? ? "amount" : "value"
        self.tables.dig(table, "analysis", var.gsub(/amount_/, ""), value_type)
      end

      # dynamic variable methods
      def amount(opts)
        table, column = opts.values_at("table", "column")

        self.tables.dig(table, "analysis", column, "amount")
      end

      def column(opts)
        opts.dig("column")
      end

      def impact(opts)
        table, column, tag = opts.values_at("table", "column", "tag")

        impact = self.tables.dig(table, "analysis", column, "tags", tag, "impact")

        opts.dig("colours").present? ? impact.send(IMPACTS[impact].colour) : impact
      end

      def table(opts)
        opts.dig("table")
      end

      def tag(opts)
        opts.dig("tag")
      end

      def value(opts)
        table, column = opts.values_at("table", "column")

        self.tables.dig(table, "analysis", column, "value")
      end
    end
  end
end
