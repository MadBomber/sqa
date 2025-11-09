# frozen_string_literal: true

require 'kbs/blackboard'

# SQA::SectorAnalyzer - Sector-based analysis with KBS blackboards
#
# Uses separate KBS blackboards for each stock sector to:
# - Track sector-wide patterns
# - Detect sector regime (bull/bear/rotation)
# - Analyze cross-stock correlations
# - Share pattern discoveries across sector
#
# Key Assumption: Stocks in the same sector tend to move together
#
# Example:
#   analyzer = SQA::SectorAnalyzer.new
#   analyzer.add_stock('AAPL', sector: :technology)
#   analyzer.add_stock('MSFT', sector: :technology)
#
#   # Discover patterns for entire tech sector
#   patterns = analyzer.discover_sector_patterns(:technology)
#
# Sectors: :technology, :finance, :healthcare, :energy, :consumer, :industrial

module SQA
  class SectorAnalyzer
    SECTORS = {
      technology: %w[AAPL MSFT GOOGL NVDA AMD INTC],
      finance: %w[JPM BAC GS MS C WFC],
      healthcare: %w[JNJ UNH PFE ABBV TMO MRK],
      energy: %w[XOM CVX COP SLB EOG MPC],
      consumer: %w[AMZN TSLA HD WMT NKE MCD],
      industrial: %w[CAT DE BA MMM HON UPS],
      materials: %w[LIN APD SHW FCX NEM DD],
      utilities: %w[NEE DUK SO D AEP EXC],
      real_estate: %w[AMT PLD CCI EQIX SPG O],
      communications: %w[META NFLX DIS CMCSA T VZ]
    }.freeze

    attr_reader :blackboards, :stocks_by_sector

    def initialize(db_dir: '/tmp/sqa_sectors')
      @blackboards = {}
      @stocks_by_sector = Hash.new { |h, k| h[k] = [] }
      @db_dir = db_dir

      # Create directory for blackboard databases
      require 'fileutils'
      FileUtils.mkdir_p(@db_dir)

      # Initialize blackboard for each sector
      SECTORS.keys.each do |sector|
        init_sector_blackboard(sector)
      end
    end

    # Add a stock to sector analysis
    #
    # @param stock [SQA::Stock, String] Stock object or ticker
    # @param sector [Symbol] Sector classification
    #
    def add_stock(stock, sector:)
      raise ArgumentError, "Unknown sector: #{sector}" unless SECTORS.key?(sector)

      ticker = stock.is_a?(String) ? stock : stock.ticker
      @stocks_by_sector[sector] << ticker unless @stocks_by_sector[sector].include?(ticker)

      # Assert fact in sector blackboard
      kb = @blackboards[sector]
      kb.add_fact(:stock_registered, {
        ticker: ticker,
        sector: sector,
        registered_at: Time.now.to_i
      })

      ticker
    end

    # Discover patterns for an entire sector
    #
    # @param sector [Symbol] Sector to analyze
    # @param stocks [Array<SQA::Stock>] Stock objects to analyze
    # @param options [Hash] Pattern discovery options
    # @return [Array<Hash>] Sector-wide patterns
    #
    def discover_sector_patterns(sector, stocks, **options)
      raise ArgumentError, "Unknown sector: #{sector}" unless SECTORS.key?(sector)

      kb = @blackboards[sector]
      all_patterns = []

      puts "=" * 70
      puts "Discovering patterns for #{sector.to_s.upcase} sector"
      puts "Analyzing #{stocks.size} stocks: #{stocks.map(&:ticker).join(', ')}"
      puts "=" * 70
      puts

      # Discover patterns for each stock
      stocks.each do |stock|
        puts "\nAnalyzing #{stock.ticker}..."

        generator = SQA::StrategyGenerator.new(stock: stock, **options)
        patterns = generator.discover_patterns

        # Assert pattern facts in blackboard
        patterns.each_with_index do |pattern, i|
          kb.add_fact(:pattern_discovered, {
            ticker: stock.ticker,
            pattern_id: "#{stock.ticker}_#{i}",
            conditions: pattern.conditions,
            frequency: pattern.frequency,
            avg_gain: pattern.avg_gain,
            sector: sector
          })

          all_patterns << {
            ticker: stock.ticker,
            pattern: pattern,
            sector: sector
          }
        end
      end

      # Detect sector-wide patterns (patterns that appear in multiple stocks)
      sector_patterns = find_common_patterns(all_patterns)

      # Assert sector-wide patterns
      sector_patterns.each do |sp|
        kb.add_fact(:sector_pattern, {
          sector: sector,
          conditions: sp[:conditions],
          stock_count: sp[:stocks].size,
          stocks: sp[:stocks],
          avg_frequency: sp[:avg_frequency],
          avg_gain: sp[:avg_gain]
        })
      end

      puts "\n" + "=" * 70
      puts "Sector Analysis Complete"
      puts "  Individual patterns found: #{all_patterns.size}"
      puts "  Sector-wide patterns: #{sector_patterns.size}"
      puts "=" * 70

      sector_patterns
    end

    # Detect sector regime
    #
    # @param sector [Symbol] Sector to analyze
    # @param stocks [Array<SQA::Stock>] Stock objects
    # @return [Hash] Sector regime information
    #
    def detect_sector_regime(sector, stocks)
      raise ArgumentError, "Unknown sector: #{sector}" unless SECTORS.key?(sector)

      kb = @blackboards[sector]

      # Detect regime for each stock
      regimes = stocks.map do |stock|
        SQA::MarketRegime.detect(stock)
      end

      # Determine consensus regime
      regime_counts = regimes.group_by { |r| r[:type] }.transform_values(&:size)
      consensus_regime = regime_counts.max_by { |_k, v| v }&.first

      # Calculate sector strength (% of stocks in bull regime)
      bull_count = regimes.count { |r| r[:type] == :bull }
      sector_strength = (bull_count.to_f / stocks.size * 100).round(2)

      result = {
        sector: sector,
        consensus_regime: consensus_regime,
        sector_strength: sector_strength,
        stock_regimes: regimes,
        detected_at: Time.now
      }

      # Assert sector regime fact
      kb.add_fact(:sector_regime, {
        sector: sector,
        regime: consensus_regime,
        strength: sector_strength,
        timestamp: Time.now.to_i
      })

      result
    end

    # Query sector blackboard
    #
    # @param sector [Symbol] Sector to query
    # @param fact_type [Symbol] Type of fact to query
    # @param pattern [Hash] Pattern to match
    # @return [Array<KBS::Fact>] Matching facts
    #
    def query_sector(sector, fact_type, pattern = {})
      kb = @blackboards[sector]
      kb.working_memory.facts.select do |fact|
        next false unless fact.type == fact_type
        pattern.all? { |key, value| fact.attributes[key] == value }
      end
    end

    # Print sector summary
    #
    # @param sector [Symbol] Sector to summarize
    #
    def print_sector_summary(sector)
      kb = @blackboards[sector]

      puts "\n" + "=" * 70
      puts "#{sector.to_s.upcase} SECTOR SUMMARY"
      puts "=" * 70

      # Count facts by type
      fact_counts = kb.working_memory.facts.group_by(&:type).transform_values(&:size)

      puts "\nFacts in Blackboard:"
      fact_counts.each do |type, count|
        puts "  #{type}: #{count}"
      end

      # Show sector regime if available
      regime_facts = query_sector(sector, :sector_regime)
      if regime_facts.any?
        latest = regime_facts.last
        puts "\nCurrent Sector Regime:"
        puts "  Type: #{latest[:regime]}"
        puts "  Strength: #{latest[:strength]}%"
      end

      # Show sector patterns if available
      pattern_facts = query_sector(sector, :sector_pattern)
      if pattern_facts.any?
        puts "\nSector-Wide Patterns: #{pattern_facts.size}"
        pattern_facts.first(3).each_with_index do |fact, i|
          puts "  #{i + 1}. Conditions: #{fact[:conditions]}"
          puts "     Stocks: #{fact[:stocks].join(', ')}"
          puts "     Avg Gain: #{fact[:avg_gain].round(2)}%"
        end
      end

      puts "=" * 70
    end

    private

    # Initialize KBS blackboard for a sector
    def init_sector_blackboard(sector)
      db_path = File.join(@db_dir, "#{sector}.db")

      # Create blackboard with persistent storage
      @blackboards[sector] = KBS::Blackboard::Engine.new(db_path: db_path)

      # Define sector-specific rules
      define_sector_rules(sector)
    end

    # Define rules for sector analysis
    def define_sector_rules(sector)
      kb = @blackboards[sector]

      # Rule: Detect sector strength
      rule = KBS::Rule.new("#{sector}_strength_detection") do |r|
        r.conditions = [
          KBS::Condition.new(:stock_registered, { sector: sector }),
          KBS::Condition.new(:pattern_discovered, { sector: sector })
        ]

        r.action = lambda do |facts, bindings|
          # Could add logic here to assert derived facts
        end
      end

      kb.add_rule(rule)
    end

    # Find patterns common across multiple stocks
    def find_common_patterns(all_patterns)
      # Group by similar conditions
      grouped = all_patterns.group_by do |p|
        p[:pattern].conditions.sort.to_h
      end

      # Find groups with multiple stocks
      common = grouped.select { |_conditions, group| group.size >= 2 }

      common.map do |conditions, group|
        {
          conditions: conditions,
          stocks: group.map { |p| p[:ticker] }.uniq,
          avg_frequency: group.map { |p| p[:pattern].frequency }.sum / group.size.to_f,
          avg_gain: group.map { |p| p[:pattern].avg_gain }.sum / group.size.to_f
        }
      end
    end
  end
end
