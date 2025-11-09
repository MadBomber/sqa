#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'base'

module Commands
  # Analyze command - Run various stock analysis methods
  class Analyze < Base
    METHODS = %w[fpop regime seasonal all].freeze

    private

    def default_options
      super.merge(
        methods: ['all'],
        fpop_periods: 10,
        regime_window: 60
      )
    end

    def add_command_options(opts)
      opts.on('-m', '--methods METHODS', Array, 'Analysis methods (comma-separated):', "  #{METHODS.join(', ')}") do |methods|
        @options[:methods] = methods.map(&:downcase)
      end

      opts.on('--fpop-periods DAYS', Integer, 'FPOP analysis periods (default: 10)') do |periods|
        @options[:fpop_periods] = periods
      end

      opts.on('--regime-window DAYS', Integer, 'Regime detection window (default: 60)') do |window|
        @options[:regime_window] = window
      end
    end

    def banner
      <<~BANNER
        Usage: sqa-cli analyze [options]

        Analyze stocks using various methods:
          - fpop:     Future Period Loss/Profit analysis
          - regime:   Market regime detection (bull/bear/sideways)
          - seasonal: Seasonal pattern analysis
          - all:      Run all analyses

        Options:
      BANNER
    end

    public

    def execute
      stock = load_stock
      print_header "Analyzing #{@options[:ticker]}"

      methods = @options[:methods].include?('all') ? %w[fpop regime seasonal] : @options[:methods]

      methods.each do |method|
        case method
        when 'fpop'
          analyze_fpop(stock)
        when 'regime'
          analyze_regime(stock)
        when 'seasonal'
          analyze_seasonal(stock)
        else
          puts "Unknown analysis method: #{method}"
        end
      end
    end

    private

    def analyze_fpop(stock)
      print_section "FPL (Future Period Loss/Profit) Analysis"

      prices = stock.df["adj_close_price"].to_a
      analysis = SQA::FPOP.fpl_analysis(prices, fpop: @options[:fpop_periods])

      puts "\nFPOP Analysis (#{@options[:fpop_periods]} days ahead):"
      puts

      # Show last 10 entries
      analysis.last(10).each_with_index do |result, idx|
        actual_idx = analysis.size - 10 + idx
        puts "Index #{actual_idx}: #{result[:interpretation]}"
        puts "  Direction: #{result[:direction]}, Magnitude: #{result[:magnitude].round(2)}%, Risk: #{result[:risk].round(2)}%"
      end

      # Filter high-quality opportunities
      puts "\nHigh-Quality Opportunities (magnitude ≥ 5%, risk ≤ 25%):"
      quality_indices = SQA::FPOP.filter_by_quality(
        analysis,
        min_magnitude: 5.0,
        max_risk: 25.0,
        directions: [:UP]
      )

      if quality_indices.empty?
        puts "  No high-quality opportunities found"
      else
        quality_indices.last(5).each do |idx|
          result = analysis[idx]
          puts "  Index #{idx}: #{result[:interpretation]}"
        end
      end
    end

    def analyze_regime(stock)
      print_section "Market Regime Detection"

      regime = SQA::MarketRegime.detect(stock, window: @options[:regime_window])

      puts "\nCurrent Market Regime:"
      puts "  Type: #{regime[:type].to_s.upcase}"
      puts "  Volatility: #{regime[:volatility].to_s.upcase}"
      puts "  Strength: #{regime[:strength].round(2)}"
      puts "  Trend: #{regime[:trend].round(2)}%"

      # Show regime history
      puts "\nRecent Regime Changes:"
      history = SQA::MarketRegime.detect_history(stock, window: @options[:regime_window])
      history.last(5).each do |r|
        puts "  #{r[:type].to_s.upcase.ljust(10)} - #{r[:duration]} days (ended #{r[:end_date]})"
      end
    end

    def analyze_seasonal(stock)
      print_section "Seasonal Pattern Analysis"

      seasonal = SQA::SeasonalAnalyzer.analyze(stock)

      puts "\nSeasonal Performance:"
      puts "  Best Months: #{seasonal[:best_months].map { |m| Date::MONTHNAMES[m] }.join(', ')}"
      puts "  Worst Months: #{seasonal[:worst_months].map { |m| Date::MONTHNAMES[m] }.join(', ')}"
      puts "  Best Quarters: Q#{seasonal[:best_quarters].join(', Q')}"
      puts "  Worst Quarters: Q#{seasonal[:worst_quarters].join(', Q')}"
      puts "  Has Seasonal Pattern: #{seasonal[:has_seasonal_pattern] ? 'YES' : 'NO'}"

      puts "\nMonthly Average Returns:"
      seasonal[:monthly_returns].sort_by { |m, _| m }.each do |month, stats|
        month_name = Date::MONTHNAMES[month].ljust(10)
        avg_return = stats[:avg_return].round(2)
        sign = avg_return >= 0 ? '+' : ''
        puts "  #{month_name}: #{sign}#{avg_return}% (#{stats[:count]} samples)"
      end

      puts "\nQuarterly Average Returns:"
      seasonal[:quarterly_returns].sort_by { |q, _| q }.each do |quarter, stats|
        avg_return = stats[:avg_return].round(2)
        sign = avg_return >= 0 ? '+' : ''
        puts "  Q#{quarter}: #{sign}#{avg_return}% (#{stats[:count]} samples)"
      end
    end
  end
end
