# frozen_string_literal: true

require_relative "helper"

module QueryPolice
  # This module provides tools to explain queries and ActiveRecord::Relation
  module Explain
    # to get explain result in parsable format
    # @param relation [ActiveRecord::Relation, String] active record relation or raw sql query
    # @return [Array] parsed_result - array of hashes representing EXPLAIN result for each row
    def full_explain(relation, detailed = true)
      explain_result = explain(relation)
      return explain_result unless detailed

      detailed_explain_result = detailed_explain(relation)

      [*explain_result.keys, *detailed_explain_result.keys].uniq.map do |key|
        (
          explain_result.dig(key)&.merge(
            detailed_explain_result.dig(key) || {}
          ) || detailed_explain_result.dig(key)
        )
      end
    end

    # to get explain result in parsable format using "EXPLAIN <query>"
    # @param relation [ActiveRecord::Relation, String] active record relation or raw sql query
    # @return [Array] parsed_result - array of hashes representing EXPLAIN result for each row
    def explain(relation)
      query = load_query(relation)
      explain_result = ActiveRecord::Base.connection.execute("EXPLAIN #{query}")
      parsed_result = {}

      explain_result.each(as: :json) do |ele|
        parsed_result[ele.dig("table")] = ele
      end

      parsed_result
    end

    # to get detailed explain result in parsable format using "EXPLAIN format=JSON <query>"
    # @param relation [ActiveRecord::Relation, String] active record relation or raw sql query
    # @param prefix [String] prefix to append before each key "prefix#<key>"
    # @return [Array] parsed_result - array of flatten hashes representing EXPLAIN result for each row
    def detailed_explain(relation, prefix = "detailed")
      query = load_query(relation)
      explain_result = ActiveRecord::Base.connection.execute("EXPLAIN format=json #{query}")
      explain_result = parse_detailed_explain(explain_result)

      explain_result.map { |ele| [ele.dig("table_name"), Helper.flatten_hash(ele, prefix)] }.to_h
    end

    class << self
      private

      def load_query(relation)
        relation.class.name == "ActiveRecord::Relation" ? relation.to_sql : relation
      end

      def parse_detailed_explain(explain_result)
        parsed_result = JSON.parse(explain_result&.first&.first || "{}").dig("query_block")
        parsed_result = parse_detailed_explain_operations(parsed_result)

        return parsed_result.dig("nested_loop").map { |e| e.dig("table") } if parsed_result.key?("nested_loop")

        parsed_result.key?("table") ? [parsed_result.dig("table")] : []
      end

      def parse_detailed_explain_operations(parsed_result)
        parsed_result = parsed_result.dig("ordering_operation") || parsed_result
        parsed_result = parsed_result.dig("grouping_operation") || parsed_result
        parsed_result = parsed_result.dig("duplicates_removal") || parsed_result

        parsed_result
      end
    end

    module_function :full_explain, :explain, :detailed_explain
  end
end
