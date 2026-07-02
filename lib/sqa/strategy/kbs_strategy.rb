# frozen_string_literal: true

require 'kbs'
require 'kbs/dsl'

#
# Knowledge-Based Strategy using RETE Forward Chaining
#
# This strategy uses a rule-based system with the RETE algorithm for
# forward-chaining inference. It allows defining complex trading rules
# that react to market conditions.
#
# The strategy asserts facts about market conditions (RSI, trends, volume, etc.)
# and fires rules when patterns are matched.
#
# DSL Keywords:
#   - on        : Assert a condition (fact must exist)
#   - without   : Negated condition (fact must NOT exist)
#   - perform   : Define action to execute when rule fires
#   - execute   : Alias for perform
#   - action    : Alias for perform
#
# Example:
#   strategy = SQA::Strategy::KBS.new
#
#   # Capture kb for use in perform blocks
#   kb = strategy.kb
#
#   # Define custom rules using the DSL
#   strategy.add_rule :buy_oversold_uptrend do
#     on :rsi, { level: :oversold }
#     on :trend, { direction: :up }
#     without :position
#
#     perform do
#       kb.assert(:signal, { action: :buy, confidence: :high })
#     end
#   end
#
#   # Execute strategy
#   signal = strategy.trade(vector)
#
# Note: Use 'kb.assert' (not just 'assert') in perform blocks to access the knowledge base.
#

module SQA
  class Strategy
    class KBS
      attr_reader :kb, :default_rules_loaded

      def initialize(load_defaults: true)
        @kb = ::KBS::DSL::KnowledgeBase.new
        @default_rules_loaded = false
        @last_signal = :hold

        load_default_rules if load_defaults
      end

      # Main strategy interface - compatible with SQA::Strategy framework
      def self.trade(vector)
        strategy = new
        strategy.execute(vector)
      end

      # Execute strategy with given market data
      def execute(vector)
        # Reset working memory
        @kb.reset

        # Assert facts from vector
        assert_market_facts(vector)

        # Run the inference engine
        @kb.run

        # Query for trading signal
        determine_signal
      end

      # Add a custom trading rule
      #
      # Example:
      #   add_rule :buy_dip do
      #     on :rsi, { value: ->(v) { v < 30 } }
      #     on :macd, { signal: :bullish }
      #     perform { kb.assert(:signal, { action: :buy, confidence: :high }) }
      #   end
      #
      # Note: Use `kb.assert` in perform blocks, not just `assert`
      def add_rule(name, &)
        # Capture kb reference for use in perform blocks

        # Define the rule with kb available in closure
        @kb.instance_eval do
          rule(name, &)
        end

        self
      end

      # Assert a fact into working memory
      def assert_fact(type, attributes = {})
        @kb.assert(type, attributes)
      end

      # Query facts from working memory
      def query_facts(type, pattern = {})
        @kb.query(type, pattern)
      end

      # Print current working memory (for debugging)
      def print_facts
        @kb.print_facts
      end

      # Print all rules (for debugging)
      def print_rules
        @kb.print_rules
      end

      private

      # Assert market condition facts from the data vector
      def assert_market_facts(vector)
        assert_rsi_facts(vector)
        assert_macd_facts(vector)
        assert_trend_facts(vector)
        assert_sma_crossover_facts(vector)
        assert_volume_facts(vector)
        assert_stochastic_facts(vector)
        assert_bollinger_facts(vector)
      end

      # RSI facts
      def assert_rsi_facts(vector)
        return unless vector.respond_to?(:rsi) && vector.rsi

        rsi_value = Array(vector.rsi).last

        assert_fact(:rsi, {
          value: rsi_value,
          level: rsi_level(rsi_value)
        })
      end

      # MACD facts
      def assert_macd_facts(vector)
        return unless vector.respond_to?(:macd) && vector.macd

        macd_line, signal_line, histogram = vector.macd
        return unless macd_line && signal_line

        current_macd = Array(macd_line).last
        current_signal = Array(signal_line).last

        assert_fact(:macd, {
          line: current_macd,
          signal: current_signal,
          histogram: Array(histogram).last,
          crossover: macd_crossover(macd_line, signal_line)
        })
      end

      # Price trend facts
      def assert_trend_facts(vector)
        return unless vector.respond_to?(:prices) && vector.prices

        prices = vector.prices
        return unless prices.size >= 20

        recent_trend = price_trend(prices.last(20))
        medium_trend = price_trend(prices.last(50)) if prices.size >= 50

        assert_fact(:trend, {
          short_term: recent_trend,
          medium_term: medium_trend || recent_trend,
          strength: trend_strength(prices)
        })
      end

      # SMA facts
      def assert_sma_crossover_facts(vector)
        return unless vector.respond_to?(:sma_short) && vector.respond_to?(:sma_long)
        return unless vector.sma_short && vector.sma_long

        short_sma = Array(vector.sma_short).last
        long_sma = Array(vector.sma_long).last

        assert_fact(:sma_crossover, {
          short: short_sma,
          long: long_sma,
          signal: sma_crossover_signal(short_sma, long_sma)
        })
      end

      # Volume facts
      def assert_volume_facts(vector)
        return unless vector.respond_to?(:volume) && vector.volume

        volumes = Array(vector.volume)
        current_volume = volumes.last
        avg_volume = volumes.last(20).sum / 20.0 if volumes.size >= 20
        return unless avg_volume

        assert_fact(:volume, {
          current: current_volume,
          average: avg_volume,
          level: volume_level(current_volume, avg_volume)
        })
      end

      # Stochastic facts
      def assert_stochastic_facts(vector)
        return unless vector.respond_to?(:stoch_k) && vector.respond_to?(:stoch_d)
        return unless vector.stoch_k && vector.stoch_d

        k_value = Array(vector.stoch_k).last
        d_value = Array(vector.stoch_d).last

        assert_fact(:stochastic, {
          k: k_value,
          d: d_value,
          zone: stoch_zone(k_value),
          crossover: stoch_crossover(vector.stoch_k, vector.stoch_d)
        })
      end

      # Bollinger Bands facts
      def assert_bollinger_facts(vector)
        return unless vector.respond_to?(:bb_upper) && vector.respond_to?(:bb_lower) && vector.respond_to?(:prices)
        return unless vector.bb_upper && vector.bb_lower && vector.prices

        current_price = Array(vector.prices).last
        upper = Array(vector.bb_upper).last
        lower = Array(vector.bb_lower).last
        middle = Array(vector.bb_middle).last if vector.respond_to?(:bb_middle)

        assert_fact(:bollinger, {
          price: current_price,
          upper: upper,
          lower: lower,
          middle: middle,
          position: bb_position(current_price, lower, upper)
        })
      end

      # Determine final trading signal from asserted signal facts
      def determine_signal
        # Query for signal facts
        buy_signals = query_facts(:signal, { action: :buy })
        sell_signals = query_facts(:signal, { action: :sell })

        # Count confidence levels
        buy_confidence = calculate_confidence(buy_signals)
        sell_confidence = calculate_confidence(sell_signals)

        # Determine signal based on confidence
        @last_signal = if buy_confidence > sell_confidence && buy_confidence >= 0.5
                         :buy
                       elsif sell_confidence > buy_confidence && sell_confidence >= 0.5
                         :sell
                       else
                         :hold
                       end

        @last_signal
      end

      # Calculate aggregate confidence from multiple signals
      def calculate_confidence(signals)
        return 0.0 if signals.empty?

        total_confidence = signals.sum do |fact|
          case fact.attributes[:confidence]
          when :high then 1.0
          when :medium then 0.6
          when :low then 0.3
          else 0.5
          end
        end

        total_confidence / signals.size.to_f
      end

      # Helper methods for fact classification

      def rsi_level(value)
        return :oversold if value < 30
        return :overbought if value > 70
        :neutral
      end

      def macd_crossover(macd_line, signal_line)
        return :none if macd_line.size < 2 || signal_line.size < 2

        curr_macd = macd_line.last
        prev_macd = macd_line[-2]
        curr_signal = signal_line.last
        prev_signal = signal_line[-2]

        if prev_macd <= prev_signal && curr_macd > curr_signal
          :bullish
        elsif prev_macd >= prev_signal && curr_macd < curr_signal
          :bearish
        else
          :none
        end
      end

      def price_trend(prices)
        return :neutral if prices.size < 2

        first_half = prices[0...(prices.size / 2)]
        second_half = prices[(prices.size / 2)..]

        avg_first = first_half.sum / first_half.size.to_f
        avg_second = second_half.sum / second_half.size.to_f

        if avg_second > avg_first * 1.02
          :up
        elsif avg_second < avg_first * 0.98
          :down
        else
          :neutral
        end
      end

      def trend_strength(prices)
        return :weak if prices.size < 10

        changes = prices.each_cons(2).map { |a, b| (b - a) / a.to_f }
        avg_change = changes.sum / changes.size.to_f

        return :strong if avg_change.abs > 0.02
        return :moderate if avg_change.abs > 0.01
        :weak
      end

      def sma_crossover_signal(short_sma, long_sma)
        return :bullish if short_sma > long_sma
        return :bearish if short_sma < long_sma
        :neutral
      end

      def volume_level(current, average)
        ratio = current / average.to_f
        return :high if ratio > 1.5
        return :low if ratio < 0.5
        :normal
      end

      def stoch_zone(value)
        return :oversold if value < 20
        return :overbought if value > 80
        :neutral
      end

      def stoch_crossover(k_values, d_values)
        return :none if k_values.size < 2 || d_values.size < 2

        curr_k = k_values.last
        prev_k = k_values[-2]
        curr_d = d_values.last
        prev_d = d_values[-2]

        if prev_k <= prev_d && curr_k > curr_d
          :bullish
        elsif prev_k >= prev_d && curr_k < curr_d
          :bearish
        else
          :none
        end
      end

      def bb_position(price, lower, upper)
        return :below if price < lower
        return :above if price > upper
        :inside
      end

      # Declarative table of default rules: each entry lists the fact
      # conditions to match (in :on order) and the signal to assert when
      # the rule fires.
      DEFAULT_RULE_DEFINITIONS = [
        { name: :buy_oversold_uptrend,
          conditions: [[:rsi, { level: :oversold }], [:trend, { short_term: :up }]],
          signal: { action: :buy, confidence: :high, reason: :oversold_uptrend } },
        { name: :sell_overbought_downtrend,
          conditions: [[:rsi, { level: :overbought }], [:trend, { short_term: :down }]],
          signal: { action: :sell, confidence: :high, reason: :overbought_downtrend } },
        { name: :buy_macd_bullish,
          conditions: [[:macd, { crossover: :bullish }], [:trend, { medium_term: :up }]],
          signal: { action: :buy, confidence: :medium, reason: :macd_crossover } },
        { name: :sell_macd_bearish,
          conditions: [[:macd, { crossover: :bearish }], [:trend, { medium_term: :down }]],
          signal: { action: :sell, confidence: :medium, reason: :macd_crossover } },
        { name: :buy_bb_lower,
          conditions: [[:bollinger, { position: :below }], [:trend, { short_term: :up }]],
          signal: { action: :buy, confidence: :medium, reason: :bollinger_bounce } },
        { name: :sell_bb_upper,
          conditions: [[:bollinger, { position: :above }], [:trend, { short_term: :down }]],
          signal: { action: :sell, confidence: :medium, reason: :bollinger_resistance } },
        { name: :buy_stoch_oversold,
          conditions: [[:stochastic, { zone: :oversold, crossover: :bullish }], [:volume, { level: :high }]],
          signal: { action: :buy, confidence: :high, reason: :stoch_oversold_volume } },
        { name: :sell_stoch_overbought,
          conditions: [[:stochastic, { zone: :overbought, crossover: :bearish }], [:volume, { level: :high }]],
          signal: { action: :sell, confidence: :high, reason: :stoch_overbought_volume } },
        { name: :buy_golden_cross,
          conditions: [[:sma_crossover, { signal: :bullish }], [:volume, { level: :high }]],
          signal: { action: :buy, confidence: :high, reason: :golden_cross } },
        { name: :sell_death_cross,
          conditions: [[:sma_crossover, { signal: :bearish }], [:volume, { level: :high }]],
          signal: { action: :sell, confidence: :high, reason: :death_cross } }
      ].freeze
      private_constant :DEFAULT_RULE_DEFINITIONS

      # Load default trading rules
      def load_default_rules
        return if @default_rules_loaded

        DEFAULT_RULE_DEFINITIONS.each { |definition| add_default_rule(definition) }

        @default_rules_loaded = true
        self
      end

      # Register a single default rule from its declarative definition.
      def add_default_rule(definition)
        kb = @kb
        conditions = definition[:conditions]
        signal = definition[:signal]

        add_rule(definition[:name]) do
          conditions.each { |type, pattern| on(type, pattern) }
          perform { kb.assert(:signal, signal) }
        end
      end
    end
  end
end
