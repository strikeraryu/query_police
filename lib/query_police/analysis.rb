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
    #     "score" => 100.0,
    #     "analysis" => {
    #       "type" => {
    #         "value" => all",
    #         "tags" => {
    #           "all" => {
    #             "impact" => "negative",
    #             "warning" => "warning to represent the issue",
    #             "suggestions" => "some follow up suggestions",
    #             "score" => 100.0
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
    #      "score" => 100.0
    #    }
    #  }
    def initialize(footer: nil)
      @footer = footer || ""
      @summary = {}
      @summary_score = 0
      @table_count = 0
      @table_score = 0
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
    #    "score" => 100.0
    #    "analysis" => {
    #      "type" => [
    #        {
    #          "tag" => "all",
    #          "impact" => "negative",
    #          "warning" => "warning to represent the issue",
    #          "suggestions" => "some follow up suggestions",
    #          "score" => 100.0
    #        }
    #      ]
    #    }
    #  }
    # @param score [Integer] score for that table
    def register_table(name, table_analysis, score)
      @table_count += 1
      tables.merge!(
        {
          name => {
            "id" => @table_count,
            "name" => name,
            "score" => score,
            "analysis" => table_analysis
          }
        }
      )

      @table_score += score
    end

    # register summary based in different attributes
    # @param summary [Hash] hash of summary of analysis
    def register_summary(summary, score)
      self.summary.merge!(summary)
      @summary_score += score
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
    def pretty_analysis(opts = { "negative" => true })
      final_message = ""
      opts = opts.with_indifferent_access

      opts.slice(*IMPACTS.keys).each do |impact, value|
        opts_ = opts.slice("wrap_width").merge({ "skip_footer" => true })
        final_message += pretty_analysis_for(impact, opts_) if value.present?
      end

      opts.dig("skip_footer").present? ? final_message : final_message + footer
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
      final_message = "query_score: #{query_score}\n\n"

      query_analytic.each_key do |table|
        table_message = query_pretty_analysis(table, { impact => true }.merge(opts))

        final_message += "#{table_message}\n" if table_message.present?
      end

      opts.dig("skip_footer").present? ? final_message : final_message + footer
    end

    # to get the final score
    def query_score
      @table_score + @summary_score
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
      table_analytics.add_row(["score", query_analytic.dig(table, "score")])

      opts = opts.with_indifferent_access

      query_analytic.dig(table, "analysis").each do |column, _|
        column_analytics = column_analytic(table, column, opts)
        next unless column_analytics.present?

        table_analytics_present = true
        table_analytics.add_separator
        table_analytics.add_row(["column", column])
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
          "score" => @summary_score,
          "analysis" => summary
        }
      )
    end

    def tag_analytic(table, column, tag, opts)
      tag_message = []

      variable_opts = { "table" => table, "column" => column, "tag" => tag }
      message = dynamic_message(variable_opts.merge({ "type" => "message" }))
      suggestion = dynamic_message(variable_opts.merge({ "type" => "suggestion" }))
      wrap_width = opts.dig("wrap_width")

      tag_message << ["impact", impact(variable_opts.merge({ "colours" => true }))]
      tag_message << ["tag_score", score(variable_opts.merge({ "colours" => true }))]
      tag_message << ["message", Helper.word_wrap(message, wrap_width)]
      tag_message << ["suggestion", Helper.word_wrap(suggestion, wrap_width)] if suggestion.present?

      tag_message
    end
  end
end
