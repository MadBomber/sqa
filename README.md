# SQA - Simple Qualitative Analysis

This is a very simplistic set of tools for running technical analysis on a stock portfolio.  Simplistic means it is not reliable nor intended for any kind of financial use.  Think of it as a training tool.  I do.  Its helping me understand why I need professional help from people who know what they are doing.

The BUY/SELL signals that it generates are part of a game.  **DO NOT USE** when real money is at stake.

## This is a Work in Progress

I'm making use of lots of gems which may not be part of the gemspec at this time.  I will be adding them as they make the final cut as to fitness for the intended function.

### DARU or RedAmber or Rover

As of v0.0.16 Daru has been dropped in favor of Rover primarily Rover is used by the Prophet gem.

* http://rubygems.org/gems/rover
* https://github.com/red-data-tools/red_amber

### Time Series Forecasting

Forecasting, predicting the future, its all a black art.  Mathematically there are ways to take a peek into the future based upon the past; however, there is no guarantee that the future will ever look like the past.  Flip a perfect coin.  What are the odds that it will come up heads?  1 out of 2.  50% right?  Now flip that same coin 100 times.  Each time the coin comes up heads.  What are the odds of of coming up heads in the next flip?  Its still 1 out of 2.  50% because the perfect coin has no memory.  What if it did have memory?  Maybe its a bitcoin? :)  You can push an analogy too far.

Some of the gems that specialize in time series forecasting are:

* https://github.com/ankane/prophet-ruby

## Installation

Install the gem and add to the application's Gemfile by executing:

    bundle add sqa

If bundler is not being used to manage dependencies, install the gem by executing:

    gem install sqa

## Usage

**Do not use!**

## Playing in IRB

You can play around in IRB with the SQA framework in two different areas.  First is the stocks and indicators.  The second is with trading strategies.

### With Stocks and Indicators

You will need some CSV files.

#### Get Historical Prices

Go to https::/finance.yahoo.com and down some historical price data for your favorite stocks.  Put those CSV files in to the `sqa_data` directory in your HOME directory.

You may need to create a `portfolio.csv` file or you may not.  TODO

The CSV files will be named by the stock's ticker symbol.  For example: AAPL.csv

```ruby
require 'sqa'
# TODO: See the documentation on configurable items
# Omit to use defaults
SQA::Config.from_file(path_to_config_file)

# initialize framework from configuration values
SQA.init

aapl = SQA::Stock.new('aapl')
```

`aapl.df` is the SQA::DataFrame
see the `rover` gem for how to manipulate the DataFrame
The SQA::Indicator class methods use Arrays not the DataFrame
Here is an example:


```ruby
prices = aapl.df.adj_close_price.to_a
period = 14 # size of the window in prices to analyze

rsi = SQA::Indicator.rsi(prices, period)
```

### With Strategies

The strategies work off of an Object that contains the information required to make its recommendation.  Build on the previous Ruby snippet ...

```ruby
require 'ostruct'
vector     = OpenStruct.new
vector.rsi = rsi

# Load some trading strategies
ss = SWA::Strategy.new
ss.auto_load # loads everything in the lib/sqa/strategy folder

# Select some strategies to execute
ss.add SWA::Strategy::Random # 3-sided coin flip
ss.add SQA::Strategy::RSI

# This is an Array with each "trade" method
# that is defined in each strategy added
ss.strategies

# Execute those strategies
results = ss.execute(vector)
```

`results` is an Array with an entry for each strategy executed.  The entries are either :buy, :sell or :hold.

Currently the strategies are executed sequentially so the results can easily be mapped back to which strategy produced which result.  In the future that will change so that the strategies are executed concurrently.  When that change is introduced the entries in the `results` object will change -- most likely to an Array of Hashes.

### See my **experiments** Repository in the **stocks** Directory

I have a program `analysis.rb` that I'm writing along with this `sqa` gem.  Its intended as a practical example/test case for how the gem can be used to analyze a complete portfolio one stock at a time.

## Contributing

I can always use some help on this stuff.  Got an idea for a new indicator or strategy?  Want to improve the math?  Make the signals better?  Let's collaborate!

Bug reports and pull requests are welcome on GitHub at https://github.com/MadBomber/sqa.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
