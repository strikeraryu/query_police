# frozen_string_literal: true

require_relative "analysis/dynamic_message"

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
    #     "id"=>1,
    #     "name"=>"users",
    #     "analysis"=>{
    #       "type"=>{
    #         "value" => "all",
    #         "tags" => {
    #           "all" => {
    #             "impact"=>"negative",
    #             "warning"=>"warning to represent the issue",
    #             "suggestions"=>"some follow up suggestions"
    #           }
    #         }
    #       }
    #     }
    #   }
    # }
    # summary [Hash] hash of analysis summary
    # Eg.
    #  {
    #    "cardinality"=>{
    #      "amount"=>10,
    #      "warning"=>"warning to represent the issue",
    #      "suggestions"=>"some follow up suggestions"
    #    }
    #  }
    def initialize
      @table_count = 0
      @tables = {}
      @summary = {}
    end

    attr_accessor :table_count, :tables, :summary

    # register a table analysis in analysis object
    # @param name [String] name of the table
    # @param table_analysis [Hash] analysis of a table
    # Eg.
    #  {
    #    "id"=>1,
    #    "name"=>"users",
    #    "analysis"=>{
    #      "type"=>[
    #        {
    #          "tag"=>"all",
    #          "impact"=>"negative",
    #          "warning"=>"warning to represent the issue",
    #          "suggestions"=>"some follow up suggestions"
    #        }
    #      ]
    #    }
    #  }
    def register_table(name, table_analysis)
      self.table_count += 1
      tables.merge!(
        {
          name => {
            "id" => self.table_count,
            "name" => name,
            "analysis" => table_analysis
          }
        }
      )
    end

    # register summary based in different attributes
    # @param summary [Hash] hash of summary of analysis
    def register_summary(summary)
      self.summary.merge!(summary)
    end

    # to get analysis in pretty format with warnings and suggestions
    # @param opts [Hash] - possible options [positive: <boolean>, negative: <boolean>, caution: <boolean>]
    # @return [String] pretty analysis
    def pretty_analysis(opts)
      final_message = ""

      opts.slice(*IMPACTS.keys).each do |impact, value|
        final_message += pretty_analysis_for(impact) if value.present?
      end

      final_message
    end

    # to get analysis in pretty format with warnings and suggestions for a impact
    # @param impact [String]
    # @return [String] pretty analysis
    def pretty_analysis_for(impact)
      final_message = ""

      tables.keys.each do |table|
        table_message = table_pretty_analysis(table, { impact => true })

        final_message += "table: #{table}\n#{table_message}\n" if table_message.present?
      end

      final_message
    end

    # to get analysis in pretty format with warnings and suggestions for a table
    # @param table [String] - table name
    # @param opts [Hash] - possible options [positive: <boolean>, negative: <boolean>, caution: <boolean>]
    # @return [String] pretty analysis
    def table_pretty_analysis(table, opts)
      table_message = ""

      tables.dig(table, "analysis").each do |column, column_analysis|
        tags_message = ""
        column_analysis.dig("tags").each do |tag, tag_analysis|
          next unless opts.dig(tag_analysis.dig("impact")).present?

          tags_message += tag_pretty_analysis(table, column, tag)
        end

        table_message += "column: #{column}\n#{tags_message}" if tags_message.present?
      end

      table_message
    end

    private

    def tag_pretty_analysis(table, column, tag)
      tag_message = ""

      opts = { "table" => table, "column" => column, "tag" => tag }
      message = dynamic_message(opts.merge({ "type" => "message" }))
      suggestion = dynamic_message(opts.merge({ "type" => "suggestion" }))
      tag_message += "impact: #{impact(opts.merge({ "colours" => true }))}\n"
      tag_message += "message: #{message}\n"
      tag_message += "suggestion: #{suggestion}\n" if suggestion.present?

      tag_message
    end
  end
end
