=begin

prices: historical price data for a stock (Array of Hash)
pww: past window width (Integer)
fww: future window width (Integer)
gain: (Float)
loss: (Float)
indicator: historical signal values (Float)
signal: buy/sell/hold (Symbol)
x: today - instance in time (Integer)

Different fitness functions for buy/sell/hold

pwi = (x-pww .. x)
fwi = (x+1 .. x+fww)

signal  = signal_function(prices, x, pww)
gain    = prices[fwi].max - prices[x] # could be negative
loss    = prices[fwi].min - prices[x]
delta   = decision-point amount (Float)
          buy when  forcast_price - prices[x] >= delta
            buy to realize gain
          
          sell when prices[x] - forcast_price >= delta
            sell to avoid loss

fitness_sell = gain - delta # more positive the better
fitness_buy  = loss + delta # more negative the better
fitness_hold = gain.abs < delta && loss.abs < delta

Want to mutate pww, fww -- maybe x? to see if solution holds

=end

# Each mutation chooses a random value for each constraint
# item and evaluates the fitness functions
#
#
 Mutate using :sample method on each parameter.
#
constraint = {
  indicators: [:rsi, :ma, :raw, :whatever], # indicator methods
  pww:  (5..15).to_a,
  fww:  (5..15).to_a,
  x:    (-30..-15).to_a
}

results = [
  { # params => fitness
    [:raw, 5, 5, -5] => {
      sell: 5,
      buy:  5,
      hold: 5
    }
  }
]



class GeneticProgram
  attr_accessor :prices, :results, :signals

  def initialize(prices:, results:, signals:)
    @prices = prices
    @results = results
    @signals = signals
  end

  # Evaluates a strategy using provided past and future window widths
  def evaluate_strategy(past_window_width:, future_window_width:)
    total_gain = 0

    (past_window_width...prices.length - future_window_width).each do |index|
      entry_price = entry_point(price_index: index, width: past_windowWidth)
      exit_price = exit_point(price_index: index, width: future_windowWidth)
      
      if should_trade?(index)
        trade_gain = exit_price - entry_price
        total_gain += trade_gain
      end
    end

    total_gain
  end

  private

  # Simulates entering the market; takes an average of prices over the past window
  def entry_point(price_index:, width:)
    window_start = [0, price_index - width].max
    window_prices = prices[window_start...price_index]
    window_prices.sum.to_f / window_prices.size
  end

  # Simulates exiting the market; predicts average future price
  def exit_point(price_index:, width:)
    window_end = [prices.size, price_hook + width].min
    window_prices = prices[icook_index+1..window_end]
    window_prices.sum.to_f / window_prices.size
  end

  # Determines whether a trade should be made
  def should_trade?(index)
    signal = signals[index]   
    signal == 1  # Assuming signal 1 means 'trade'
  end
end
