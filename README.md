# SQA - Simple Qualitative Analysis

This is a very simplistic set of tools for running technical analysis (quantitative and qualitative) on a stock portfolio.  Simplistic means it is not reliable nor intended for any kind of mission-critical financial use.  Think of it as a training tool.  I do.  Its helping me understand why I need professional help from people who know what they are doing.

The BUY/SELL signals that it generates should not be taken seriously.  **DO NOT USE** this library when real money is at stake.  If you lose your shirt playing in the stock market don't come crying to me.  I think playing in the market is like playing in the street.  You are going to get run over.

## This is a Work in Progress

I am experimenting with different gems to support various functionality.  Sometimes they do not work out well.  For example I've gone through two different gems to implement the data frame capability.  Neither did what I wanted so I ended up creating my own data frame class based upon the old tried and true Hashie library.


## Installation

Install the gem and add to the application's Gemfile by executing:

    bundle add sqa

If bundler is not being used to manage dependencies, install the gem by executing:

    gem install sqa

### Semantic Versioning

```ruby
SQA.version # returns SemVersion object
exit(1) unless SQA.version >= SemVersion("1.0.0")
```

## Usage

**Do not use!** but its okay to play with.

`SQA` can be used from the command line or as a library in your own application.

`SQA` has a command line component.

```plaintext
$ sqa --help
Stock Quantitative Analysis (SQA)

Usage: sqa [analysis|web] [OPTIONS]

A collection of things

Options:
  -c, --config string             Path to the config file
      --data-dir string           Set the directory for the SQA data
  -d, --debug                     Turn on debugging output
      --dump-config path_to_file  Dump the current configuration
  -h, --help                      Print usage
  -l, --log_level string          Set the log level (debug, info, warn, error,
                                  fatal)
  -p, --portfolio string          Set the filename of the portfolio
  -t, --trades string             Set the filename into which trades are
                                  stored
  -v, --verbose                   Print verbosely
      --version                   Print version

Examples:
  sqa -c ~/.sqa.yml -p portfolio.csv -t trades.csv --data-dir ~/sqa_data

  Optional Command Available:
    analysis - Provide an Analysis of a Portfolio
    web - Run a web server

WARNING: This is a toy, a play thing, not intended for serious use.
```
### Setup a Config File

You will need to create a directory to store the `sqa` data and a configuration file.  You can start by doing this:

```ruby
gem install sqa
mkdir ~/Documents/sqa_data
sqa --data-dir ~/Documents/sqa_data --dump-config ~/.sqa.yml
```

By default `SQA` looks for a configuration file named `.sqa.yml` in the current directory.  If it does not find one there it looks in the home directory.  You can use the `--config` CLI option to specify a path to your custom config file name.


### AlphaVantage

`SQA` makes use of the `AlphaVantage` API to get some stock related information.  You will need an API key in order to use this functionality.  They have a free rate limited API key which allows 5 accesses per second; total of 100 accesses in a day.  If you are doing more than that you are not playing an ought to purchase one of there serious API key plans.

[https://www.alphavantage.co/](https://www.alphavantage.co/)


## Playing in IRB

You can play around in IRB with the SQA framework.


### With Stocks and Indicators

You will need some CSV files.  If you ask for a stock to which you have not existing historical price data in a CSV file, `SQA` can use either Alpha Vantage or Yahoo Finance to get some data.  I like Alpha Vantage better because it has a well defined and documented API.  Yahoo Finance on the other hand does not.  You can manually download historical stock price data from Yahoo Finance into you `sqa data directory`

Historical price data is kept in the `SQA.data_dir` in a CSV file whose name is all lowercase.  If you download the CSV file for the stock symbol "AAPL" it should be saved in you `SQA.data_dir` as `aapl.csv`

#### Get Historical Prices

Go to https::/finance.yahoo.com and down some historical price data for your favorite stocks.  Put those CSV files into the `SQA.data_dir`.

You may need to create a `portfolio.csv` file or you may not.  TODO

The CSV files will be named by the stock's ticker symbol.  For example: `aapl.csv`

### Playing in the IRB - Setup

```ruby
require 'sqa'
require 'sqa/cli'

# You can pass a set of CLI options in a String
SQA.init "-c ~/.sqa.yml"

aapl = SQA::Stock.new(ticker: 'aapl', source: :alpha_vantage)
#=> aapl with 1207 data points from 2019-01-02 to 2023-10-17
```

`aapl.df`   is the data frame.  It is implemented as a Hashie::Mash obect -- a Hash or Arrays.

```ruby
aapl.df.keys
#=> [:timestamp, :open_price, :high_price, :low_price, :close_price, :adj_close_price, :volume]

aapl.df.adj_close_price.last(5)
#=> [179.8, 180.71, 178.85, 178.72, 177.15]
```

`aapl.data` is basic static data, company name, industry etc.  It is also implemented as a Hassie::Mash object but is primary treated as a plain hash object.

```ruby
aapl.data.keys
#=> [:ticker, :source, :indicators, :overview]

aapl.data.source
=> "alpha_vantage"

aapl.data.overciew.keys
=> [:symbol, :asset_type, :name, :description, :cik, :exchange, :currency, :country, :sector, :industry, :address, :fiscal_year_end, :latest_quarter, :market_capitalization, :ebitda, :pe_ratio, :peg_ratio, :book_value, :dividend_per_share, :dividend_yield, :eps, :revenue_per_share_ttm, :profit_margin, :operating_margin_ttm, :return_on_assets_ttm, :return_on_equity_ttm, :revenue_ttm, :gross_profit_ttm, :diluted_epsttm, :quarterly_earnings_growth_yoy, :quarterly_revenue_growth_yoy, :analyst_target_price, :trailing_pe, :forward_pe, :price_to_sales_ratio_ttm, :price_to_book_ratio, :ev_to_revenue, :ev_to_ebitda, :beta, :"52_week_high", :"52_week_low", :"50_day_moving_average", :"200_day_moving_average", :shares_outstanding, :dividend_date, :ex_dividend_date]

```

### Playing in the IRB - Statistics

Basic statistics are available on all of the SQA::DataFrame arrays.

```ruby
require 'amazing_print' # to get the ap command

# Look at some summary stats on the last 5 days of
# adjusted closing pricess of AAPL
ap aapl.df.adj_close_price.last(5).summary
{
                        :frequencies => {
         179.8 => 1,
        180.71 => 1,
        178.85 => 1,
        178.72 => 1,
        177.15 => 1
    },
                                :max => 180.71,
                               :mean => 179.046,
                             :median => 178.85,
                           :midrange => 178.93,
                                :min => 177.15,
                               :mode => nil,
                        :proportions => {
         179.8 => 0.2,
        180.71 => 0.2,
        178.85 => 0.2,
        178.72 => 0.2,
        177.15 => 0.2
    },
                          :quartile1 => 178.85,
                          :quartile2 => 179.8,
                          :quartile3 => 180.71,
                              :range => 3.5600000000000023,
                               :size => 5,
                                :sum => 895.23,
    :sample_coefficient_of_variation => 0.006644656242680533,
                    :sample_kurtosis => 2.089087404921432,
                        :sample_size => 5,
                    :sample_skewness => -0.2163861377512453,
          :sample_standard_deviation => 1.1896991216269788,
              :sample_standard_error => 0.532049621745943,
                    :sample_variance => 1.415384000000005,
                     :sample_zscores => {
         179.8 => 0.6337736880639895,
        180.71 => 1.3986729667618856,
        178.85 => -0.16474753695031497,
        178.72 => -0.2740188624785824,
        177.15 => -1.5936802553969298
    }
}
#=> nil
```

### Playing in the IRB - Indicators

The SQA::Indicator class methods use Arrays not the DataFrame
Here is an example:


```ruby
prices = aapl.df.adj_close_price
period = 14 # size of the window in prices to analyze

rsi = SQA::Indicator.rsi(prices, period)
#=> {:rsi=>63.46652828230407, :trend=>:normal}
```

### Playing in the IRB - Strategies

The strategies work off of an Object that contains the information required to make its recommendation.  Building on the previous Ruby snippet ...

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
ap ss.strategies
[
    [0] SQA::Strategy::Random#trade(vector),
    [1] SQA::Strategy::RSI#trade(vector)
]

# Execute those strategies
results = ss.execute(vector)
#=> [:hold, :hold]
```

`results` is an Array with an entry for each strategy executed.  The entries are either :buy, :sell or :hold.

Currently the strategies are executed sequentially so the results can easily be mapped back to which strategy produced which result.  In the future that will change so that the strategies are executed concurrently.  When that change is introduced the entries in the `results` object will change -- most likely to an Array of Hashes.

Any specific strategy may not work on every stock. Using the historical data, it is possible to see which strategy works better for a specific stock.  **Of course the statistical motto is that historical performance is not a fail-proof indicator for future performance.**

The strategies that come with the `SQA::Strategy` class are examples only.  Its expected that you will come up with your own.  If you do, consider sharing them.

## Contributing

I can always use some help on this stuff.  Got an idea for a new indicator or strategy?  Want to improve the math?  Make the signals better?  Let's collaborate!

Bug reports and pull requests are welcome on GitHub at https://github.com/MadBomber/sqa.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
