# frozen_string_literal: true

require 'kbs'
require 'kbs/dsl'

=begin

Knowledge-Based Strategy using RETE Forward Chaining

This strategy uses a rule-based system with the RETE algorithm for
forward-chaining inference. It allows defining complex trading rules
that react to market conditions.

The strategy asserts facts about market conditions (RSI, trends, volume, etc.)
and fires rules when patterns are matched.

Example:
  strategy = SQA::Strategy::KBS.new

  # Define custom rules
  strategy.add_rule :buy_oversold_uptrend do
    on :rsi, { level: :oversold }
    on :trend, { direction: :up }
    without :position
    then { :buy }
  end

  # Execute strategy
  signal = strategy.trade(vector)

=end

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
      #     then { assert(:signal, { action: :buy, confidence: :high }) }
      #   end
      def add_rule(name, &block)
        @kb.rule(name, &block)
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
        # RSI facts
        if vector.respond_to?(:rsi) && vector.rsi
          rsi_value = Array(vector.rsi).last

          assert_fact(:rsi, {
            value: rsi_value,
            level: rsi_level(rsi_value)
          })
        end

        # MACD facts
        if vector.respond_to?(:macd) && vector.macd
          macd_line, signal_line, histogram = vector.macd

          if macd_line && signal_line
            current_macd = Array(macd_line).last
            current_signal = Array(signal_line).last

            assert_fact(:macd, {
              line: current_macd,
              signal: current_signal,
              histogram: Array(histogram).last,
              crossover: macd_crossover(macd_line, signal_line)
            })
          end
        end

        # Price trend facts
        if vector.respond_to?(:prices) && vector.prices
          prices = vector.prices

          if prices.size >= 20
            recent_trend = price_trend(prices.last(20))
            medium_trend = price_trend(prices.last(50)) if prices.size >= 50

            assert_fact(:trend, {
              short_term: recent_trend,
              medium_term: medium_trend || recent_trend,
              strength: trend_strength(prices)
            })
          end
        end

        # SMA facts
        if vector.respond_to?(:sma_short) && vector.respond_to?(:sma_long)
          if vector.sma_short && vector.sma_long
            short_sma = Array(vector.sma_short).last
            long_sma = Array(vector.sma_long).last

            assert_fact(:sma_crossover, {
              short: short_sma,
              long: long_sma,
              signal: sma_crossover_signal(short_sma, long_sma)
            })
          end
        end

        # Volume facts
        if vector.respond_to?(:volume) && vector.volume
          volumes = Array(vector.volume)
          current_volume = volumes.last
          avg_volume = volumes.last(20).sum / 20.0 if volumes.size >= 20

          if avg_volume
            assert_fact(:volume, {
              current: current_volume,
              average: avg_volume,
              level: volume_level(current_volume, avg_volume)
            })
          end
        end

        # Stochastic facts
        if vector.respond_to?(:stoch_k) && vector.respond_to?(:stoch_d)
          if vector.stoch_k && vector.stoch_d
            k_value = Array(vector.stoch_k).last
            d_value = Array(vector.stoch_d).last

            assert_fact(:stochastic, {
              k: k_value,
              d: d_value,
              zone: stoch_zone(k_value),
              crossover: stoch_crossover(vector.stoch_k, vector.stoch_d)
            })
          end
        end

        # Bollinger Bands facts
        if vector.respond_to?(:bb_upper) && vector.respond_to?(:bb_lower) && vector.respond_to?(:prices)
          if vector.bb_upper && vector.bb_lower && vector.prices
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
        end
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
        if buy_confidence > sell_confidence && buy_confidence >= 0.5
          @last_signal = :buy
        elsif sell_confidence > buy_confidence && sell_confidence >= 0.5
          @last_signal = :sell
        else
          @last_signal = :hold
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

        first_half = prices[0...prices.size/2]
        second_half = prices[prices.size/2..-1]

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

      # Load default trading rules
      def load_default_rules
        return if @default_rules_loaded

        # Rule 1: Buy on RSI oversold in uptrend
        add_rule :buy_oversold_uptrend do
          on :rsi, { level: :oversold }
          on :trend, { short_term: :up }
          send(:then) do
            assert(:signal, { action: :buy, confidence: :high, reason: :oversold_uptrend })
          end
        end

        # Rule 2: Sell on RSI overbought in downtrend
        add_rule :sell_overbought_downtrend do
          on :rsi, { level: :overbought }
          on :trend, { short_term: :down }
          send(:then) do
            assert(:signal, { action: :sell, confidence: :high, reason: :overbought_downtrend })
          end
        end

        # Rule 3: Buy on bullish MACD crossover
        add_rule :buy_macd_bullish do
          on :macd, { crossover: :bullish }
          on :trend, { medium_term: :up }
          send(:then) do
            assert(:signal, { action: :buy, confidence: :medium, reason: :macd_crossover })
          end
        end

        # Rule 4: Sell on bearish MACD crossover
        add_rule :sell_macd_bearish do
          on :macd, { crossover: :bearish }
          on :trend, { medium_term: :down }
          send(:then) do
            assert(:signal, { action: :sell, confidence: :medium, reason: :macd_crossover })
          end
        end

        # Rule 5: Buy at lower Bollinger Band
        add_rule :buy_bb_lower do
          on :bollinger, { position: :below }
          on :trend, { short_term: :up }
          send(:then) do
            assert(:signal, { action: :buy, confidence: :medium, reason: :bollinger_bounce })
          end
        end

        # Rule 6: Sell at upper Bollinger Band
        add_rule :sell_bb_upper do
          on :bollinger, { position: :above }
          on :trend, { short_term: :down }
          send(:then) do
            assert(:signal, { action: :sell, confidence: :medium, reason: :bollinger_resistance })
          end
        end

        # Rule 7: Buy on stochastic oversold crossover
        add_rule :buy_stoch_oversold do
          on :stochastic, { zone: :oversold, crossover: :bullish }
          on :volume, { level: :high }
          send(:then) do
            assert(:signal, { action: :buy, confidence: :high, reason: :stoch_oversold_volume })
          end
        end

        # Rule 8: Sell on stochastic overbought crossover
        add_rule :sell_stoch_overbought do
          on :stochastic, { zone: :overbought, crossover: :bearish }
          on :volume, { level: :high }
          send(:then) do
            assert(:signal, { action: :sell, confidence: :high, reason: :stoch_overbought_volume })
          end
        end

        # Rule 9: SMA golden cross (buy)
        add_rule :buy_golden_cross do
          on :sma_crossover, { signal: :bullish }
          on :volume, { level: :high }
          send(:then) do
            assert(:signal, { action: :buy, confidence: :high, reason: :golden_cross })
          end
        end

        # Rule 10: SMA death cross (sell)
        add_rule :sell_death_cross do
          on :sma_crossover, { signal: :bearish }
          on :volume, { level: :high }
          send(:then) do
            assert(:signal, { action: :sell, confidence: :high, reason: :death_cross })
          end
        end

        @default_rules_loaded = true
        self
      end
    end
  end
end
