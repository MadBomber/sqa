# frozen_string_literal: true

# SQA::FPOP - Future Period of Performance Analysis
#
# This module provides utilities for analyzing potential future price movements
# from any given point in a price series. It calculates the range of possible
# outcomes (min/max deltas) during a future period, along with risk metrics
# and directional classification.
#
# Key Concepts:
# - FPL (Future Period Loss/Profit): Min and max percentage change during fpop
# - Risk: Volatility range (max_delta - min_delta)
# - Direction: Classification of movement (UP/DOWN/UNCERTAIN/FLAT)
# - Magnitude: Average expected movement
#
# Example:
#   prices = [100, 102, 98, 105, 110, 115, 120]
#
#   # Get raw FPL data
#   fpl_data = SQA::FPOP.fpl(prices, fpop: 3)
#   # => [[-2.0, 10.0], [-4.9, 17.6], ...]
#
#   # Get detailed analysis
#   analysis = SQA::FPOP.fpl_analysis(prices, fpop: 3)
#   # => [{min_delta: -2.0, max_delta: 10.0, risk: 12.0, direction: :UNCERTAIN, ...}, ...]

module SQA
  module FPOP
    class << self
      # Calculate Future Period Loss/Profit for each point in price series
      #
      # For each price point, looks ahead fpop periods and calculates:
      # - Minimum percentage change (worst loss)
      # - Maximum percentage change (best gain)
      #
      # @param price [Array<Numeric>] Array of prices
      # @param fpop [Integer] Future Period of Performance (days to look ahead)
      # @return [Array<Array<Float, Float>>] Array of [min_delta, max_delta] pairs
      #
      # @example
      #   SQA::FPOP.fpl([100, 105, 95, 110], fpop: 2)
      #   # => [[-5.0, 5.0], [-9.52, 4.76], [15.79, 15.79]]
      #
      def fpl(price, fpop: 14)
        validate_fpl_inputs(price, fpop)

        price_floats = price.map(&:to_f)
        result = []

        price_floats.each_with_index do |current_price, index|
          future_prices = price_floats[(index + 1)..(index + fpop)]
          break if future_prices.nil? || future_prices.empty?

          deltas = future_prices.map { |p| ((p - current_price) / current_price) * 100.0 }
          result << [deltas.min, deltas.max]
        end

        result
      end

      # Perform comprehensive FPL analysis with risk metrics and classification
      #
      # @param price [Array<Numeric>] Array of prices
      # @param fpop [Integer] Future Period of Performance
      # @return [Array<Hash>] Array of analysis hashes containing:
      #   - :min_delta - Worst percentage loss during fpop
      #   - :max_delta - Best percentage gain during fpop
      #   - :risk - Volatility range (max - min)
      #   - :direction - Movement classification (:UP, :DOWN, :UNCERTAIN, :FLAT)
      #   - :magnitude - Average expected movement
      #   - :interpretation - Human-readable summary
      #
      # @example
      #   analysis = SQA::FPOP.fpl_analysis([100, 110, 120], fpop: 2)
      #   analysis.first
      #   # => {
      #   #   min_delta: 10.0,
      #   #   max_delta: 20.0,
      #   #   risk: 10.0,
      #   #   direction: :UP,
      #   #   magnitude: 15.0,
      #   #   interpretation: "UP: 15.0% (±5.0% risk)"
      #   # }
      #
      def fpl_analysis(price, fpop: 14)
        validate_fpl_inputs(price, fpop)

        fpl_results = fpl(price, fpop: fpop)

        fpl_results.map do |min_delta, max_delta|
          {
            min_delta: min_delta,
            max_delta: max_delta,
            risk: (max_delta - min_delta).abs,
            direction: determine_direction(min_delta, max_delta),
            magnitude: calculate_magnitude(min_delta, max_delta),
            interpretation: build_interpretation(min_delta, max_delta)
          }
        end
      end

      # Determine directional bias from min/max deltas
      #
      # @param min_delta [Float] Minimum percentage change
      # @param max_delta [Float] Maximum percentage change
      # @return [Symbol] :UP, :DOWN, :UNCERTAIN, or :FLAT
      #
      def determine_direction(min_delta, max_delta)
        if min_delta > 0 && max_delta > 0
          :UP
        elsif min_delta < 0 && max_delta < 0
          :DOWN
        elsif min_delta < 0 && max_delta > 0
          :UNCERTAIN
        else
          :FLAT
        end
      end

      # Calculate average expected movement (magnitude)
      #
      # @param min_delta [Float] Minimum percentage change
      # @param max_delta [Float] Maximum percentage change
      # @return [Float] Average of min and max deltas
      #
      def calculate_magnitude(min_delta, max_delta)
        (min_delta + max_delta) / 2.0
      end

      # Build human-readable interpretation string
      #
      # @param min_delta [Float] Minimum percentage change
      # @param max_delta [Float] Maximum percentage change
      # @return [String] Formatted interpretation
      #
      def build_interpretation(min_delta, max_delta)
        direction = determine_direction(min_delta, max_delta)
        magnitude = calculate_magnitude(min_delta, max_delta)
        risk = (max_delta - min_delta).abs

        "#{direction}: #{magnitude.round(2)}% (±#{(risk / 2).round(2)}% risk)"
      end

      # Filter FPL analysis results by criteria
      #
      # Useful for finding high-quality trading opportunities
      #
      # @param analysis [Array<Hash>] FPL analysis results
      # @param min_magnitude [Float] Minimum average movement (default: nil)
      # @param max_risk [Float] Maximum acceptable risk (default: nil)
      # @param directions [Array<Symbol>] Acceptable directions (default: [:UP, :DOWN, :UNCERTAIN, :FLAT])
      # @return [Array<Integer>] Indices of points that meet criteria
      #
      # @example Find low-risk bullish opportunities
      #   analysis = SQA::FPOP.fpl_analysis(prices, fpop: 10)
      #   indices = SQA::FPOP.filter_by_quality(
      #     analysis,
      #     min_magnitude: 5.0,
      #     max_risk: 10.0,
      #     directions: [:UP]
      #   )
      #
      def filter_by_quality(analysis, min_magnitude: nil, max_risk: nil, directions: [:UP, :DOWN, :UNCERTAIN, :FLAT])
        indices = []

        analysis.each_with_index do |result, idx|
          next if min_magnitude && result[:magnitude] < min_magnitude
          next if max_risk && result[:risk] > max_risk
          next unless directions.include?(result[:direction])

          indices << idx
        end

        indices
      end

      # Calculate risk-reward ratio for each analysis point
      #
      # @param analysis [Array<Hash>] FPL analysis results
      # @return [Array<Float>] Risk-reward ratios (magnitude / risk)
      #
      def risk_reward_ratios(analysis)
        analysis.map do |result|
          result[:risk] > 0 ? result[:magnitude].abs / result[:risk] : 0.0
        end
      end

      private

      # Validate FPL input parameters
      def validate_fpl_inputs(price, fpop)
        raise ArgumentError, "price must be an Array" unless price.is_a?(Array)
        raise ArgumentError, "price cannot be empty" if price.empty?
        raise ArgumentError, "fpop must be a positive integer" unless fpop.is_a?(Integer) && fpop > 0
        raise ArgumentError, "prices must not contain zero or negative values" if price.any? { |p| p <= 0 }
      end
    end
  end
end
