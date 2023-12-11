# frozen_string_literal: true

require_relative "analysis/dynamic_message"
require_relative "helper"

module QueryPolice
  # This class is used to store analysis of a query and provide methods over them
  class Analysis
    include DynamicMessage

    IMPACTS = {
      "negative" => { "colour" => "red" },
      "positive" => { "colour" => "green" },
      "caution" => { "colour" => "yellow" }
    }.freeze

    # initialize analysis object
    # tables [Array] Array of table analysis
    # Eg.
    # {
    #   "users" => {
    #     "id" => 1,
    #     "name" => "users",
    #     "debt" => 100.0,
    #     "analysis" => {
    #       "type" => {
    #         "value" => all",
    #         "tags" => {
    #           "all" => {
    #             "impact" => "negative",
    #             "warning" => "warning to represent the issue",
    #             "suggestions" => "some follow up suggestions",
    #             "debt" => 100.0
    #           }
    #         }
    #       }
    #     }
    #   }
    # }
    # summary [Hash] hash of analysis summary
    # Eg.
    #  {
    #    "cardinality" => {
    #      "amount" => 10,
    #      "warning" => "warning to represent the issue",
    #      "suggestions" => "some follow up suggestions",
    #      "debt" => 100.0
    #    }
    #  }
    def initialize(config: nil)
      @debt_ranges = config&.analysis_debt_ranges || []
      @footer = config&.analysis_footer || ""
      @summary = {}
      @summary_debt = 0
      @table_count = 0
      @table_debt = 0
      @tables = {}
    end

    attr_accessor :summary, :tables

    # register a table analysis in analysis object
    # @param name [String] name of the table
    # @param table_analysis [Hash] analysis of a table
    # Eg.
    #  {
    #    "id" => 1,
    #    "name" => "users",
    #    "debt" => 100.0
    #    "analysis" => {
    #      "type" => [
    #        {
    #          "tag" => "all",
    #          "impact" => "negative",
    #          "warning" => "warning to represent the issue",
    #          "suggestions" => "some follow up suggestions",
    #          "debt" => 100.0
    #        }
    #      ]
    #    }
    #  }
    # @param debt [Integer] debt for that table
    def register_table(name, table_analysis, debt)
      @table_count += 1
      tables.merge!(
        {
          name => {
            "id" => @table_count,
            "name" => name,
            "debt" => debt,
            "analysis" => table_analysis
          }
        }
      )

      @table_debt += debt
    end

    # register summary based in different attributes
    # @param summary [Hash] hash of summary of analysis
    def register_summary(summary, debt)
      self.summary.merge!(summary)
      @summary_debt += debt
    end

    # to get analysis in pretty format with warnings and suggestions
    # @param opts [Hash] - options
    # possible keys
    # [
    #   positive: <boolean>,
    #   negative: <boolean>,
    #   caution: <boolean>,
    #   wrap_width: <integer>,
    #   skip_footer: <boolean>
    # ]
    # @return [String] pretty analysis
    def pretty_analysis(opts = { "negative" => true, "caution" => true })
      final_message = ""
      opts = opts.with_indifferent_access

      query_analytic.each_key do |table|
        table_message = query_pretty_analysis(table, opts)

        final_message += "#{table_message}\n" if table_message.present?
      end

      return final_message unless final_message.present?

      final_message = "\n#{pretty_query_debt}\n\n#{final_message}"
      opts.dig("skip_footer").present? ? final_message : final_message + @footer
    end

    # to get analysis in pretty format with warnings and suggestions for a impact
    # @param impact [String]
    # @param opts [Hash] - options
    # possible keys
    # [
    #   wrap_width: <integer>
    #   skip_footer: <boolean>
    # ]
    # @return [String] pretty analysis
    def pretty_analysis_for(impact, opts = {})
      pretty_analysis({ impact => true }.merge(opts))
    end

    # to get the final debt in pretty form
    def pretty_query_debt
      range = query_debt_range
      debt_message = query_debt.to_s
      debt_message += " (#{range.dig("message")})" if range&.dig("message").present?
      debt_message = Helper.colorize(debt_message, range.dig("colour")&.to_sym) if range&.dig("colour").present?

      Terminal::Table.new do |t|
        t.add_row(["Total Query Debt", debt_message])
      end
    end

    # to get the final debt
    def query_debt
      @table_debt + @summary_debt
    end

    # to get the final debt range
    def query_debt_range
      return nil unless @debt_ranges.present?

      @debt_ranges.each do |range_config|
        range_config = range_config.wida
        return range_config if range_config.dig("range")&.include?(query_debt)
      end

      nil
    end

    # to get analysis in pretty format with warnings and suggestions for a table
    # @param table [String] - table name
    # @param opts [Hash] - options
    # possible keys
    # [
    #   positive: <boolean>,
    #   negative: <boolean>,
    #   caution: <boolean>,
    #   wrap_width: <integer>
    # ]
    # @return [String] pretty analysis
    def query_pretty_analysis(table, opts)
      table_analytics = Terminal::Table.new(title: table)
      table_analytics_present = false
      table_analytics.add_row(["Debt", query_analytic.dig(table, "debt")])

      opts = opts.with_indifferent_access

      query_analytic.dig(table, "analysis").each do |column, _|
        column_analytics = column_analytic(table, column, opts)
        next unless column_analytics.present?

        table_analytics_present = true
        table_analytics.add_separator
        table_analytics.add_row(["Column", column])
        column_analytics.each { |row| table_analytics.add_row(row) }
      end

      table_analytics_present ? table_analytics : nil
    end

    private

    def column_analytic(table, column, opts)
      column_analytics = []

      query_analytic.dig(table, "analysis", column, "tags").each do |tag, tag_analysis|
        next unless opts.dig(tag_analysis.dig("impact")).present?

        column_analytics += tag_analytic(table, column, tag, opts)
      end

      column_analytics
    end

    def query_analytic
      tables.merge(
        "summary" => {
          "name" => "summary",
          "debt" => @summary_debt,
          "analysis" => summary
        }
      )
    end

    def tag_analytic(table, column, tag, opts)
      variable_opts = { "table" => table, "column" => column, "tag" => tag }
      message = dynamic_message(variable_opts.merge({ "type" => "message" }))
      suggestion = dynamic_message(variable_opts.merge({ "type" => "suggestion" }))
      wrap_width = opts.dig("wrap_width")

      tag_message = [
        ["Value", Helper.word_wrap(value(variable_opts).to_s, width: wrap_width, cut: true)],
        ["Impact", impact(variable_opts.merge({ "colours" => true }))],
        ["Tag Debt", debt(variable_opts.merge({ "colours" => true }))],
        ["Message", Helper.word_wrap(message, width: wrap_width)]
      ]
      tag_message << ["Suggestion", Helper.word_wrap(suggestion, width: wrap_width)] if suggestion.present?

      tag_message
    end
  end
end
