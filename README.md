This project is on hold pending a complete refactoring that will include a GPT approach to trading strategy analysis.


# SQA - Simple Qualitative Analysis

[![Badges?](https://img.shields.io/badge/Badge-We%20don't%20need%20no%20stinkin'%20badges!-red)](https://www.youtube.com/watch?v=VqomZQMZQCQ)

This is a very simplistic set of tools for running technical analysis (quantitative and qualitative) on a stock portfolio.  Simplistic means it is not reliable nor intended for any kind of mission-critical financial use.  Think of it as a training tool.  I do.  Its helping me understand why I need professional help from people who know what they are doing.

The BUY/SELL signals that it generates should not be taken seriously.  **DO NOT USE** this library when real money is at stake.  If you lose your shirt playing in the stock market don't come crying to me.  I think playing in the market is like playing in the street.  You are going to get run over.

<!-- TODO: Consider these gems ...

This one is most likely out of date:
    yahoofinance-ruby: This gem provides a simple Ruby interface to Yahoo Finance's historical quote data. If you're looking to add more data sources to your project, this could be a useful addition. yahoofinance-ruby

Worth Looking at:
    ruby-technical-analysis: This gem provides various technical analysis calculations. It includes over 60 technical analysis functions and indicators like RSI, EMA, SMA, Bollinger Bands, MACD, and more. ruby-technical-analysis

Maybe later if I want to add an ability to make a live trade from within the SQA context...
    ib-ruby: This gem provides a Ruby interface to Interactive Brokers' Trader Workstation (TWS) API, allowing you to build algorithmic trading strategies in Ruby. ib-ruby

Definitely looking for a plotting package.
    plottable: If you're looking to add more visualization capabilities to your project, this gem could be useful. It provides a simple and flexible API for creating plots and charts in Ruby. plottable

Currently using CSV files; maybe switch to an RDBMS ...
    activerecord-import: If you're dealing with large amounts of data, this gem could help improve performance. It adds methods to ActiveRecord for bulk inserting data into the database. activerecord-import

Could spawn off separate agents for each stock within a portfolio for analysis ...
    parallel: This gem can help improve performance by allowing you to run code in parallel. This could be useful if you're running complex calculations on large datasets. parallel

-->



<!-- Tocer[start]: Auto-generated, don't remove. -->

## Table of Contents

  - [This is a Work in Progress](#this-is-a-work-in-progress)
  - [Recent Changes](#recent-changes)
  - [Installation](#installation)
  - [Semantic Versioning](#semantic-versioning)
  - [Usage](#usage)
    - [Setup a Config File](#setup-a-config-file)
    - [AlphaVantage](#alphavantage)
    - [TradingView](#tradingview)
    - [Yahoo Finance](#yahoo-finance)
  - [Playing in IRB](#playing-in-irb)
    - [With Stocks and Indicators](#with-stocks-and-indicators)
      - [Get Historical Prices](#get-historical-prices)
    - [Playing in the IRB - Setup](#playing-in-the-irb---setup)
    - [Playing in the IRB - Statistics](#playing-in-the-irb---statistics)
    - [Playing in the IRB - Indicators](#playing-in-the-irb---indicators)
    - [Playing in the IRB - Strategies](#playing-in-the-irb---strategies)
  - [Included Program Examples](#included-program-examples)
    - [Analysis](#analysis)
    - [Web](#web)
  - [Predicted FAQ](#predicted-faq)
  - [Other Similar Projects](#other-similar-projects)
  - [Contributing](#contributing)
  - [License](#license)

<!-- Tocer[finish]: Auto-generated, don't remove. -->

## This is a Work in Progress

I am experimenting with different gems to support various functionality.  Sometimes they do not work out well.  For example I've gone through two different gems to implement the data frame capability.  Neither did what I wanted so I ended up creating my own data frame class based upon the old tried and true [Hashie](https://github.com/intridea/hashie) library.

## Recent Changes

* 0.0.24 - Replaced tty-option with dry-cli

## Installation

Install the gem and add to the application's Gemfile by executing:

    bundle add sqa

If bundler is not being used to manage dependencies, install the gem by executing:

    gem install sqa

## Semantic Versioning

`sqa` uses the [sem_version](https://github.com/canton7/sem_version) gem to provide a semantic version object.  Sure its old; but, so am I.  Doesn't mean we can't do the job.

```ruby
# On the command line:
sqa --version

# or inside your program:

SQA.version # returns SemVersion object
exit(1) unless SQA.version >= SemVersion("1.0.0")

# Okay, you're right, you could put that kind of version
# constraint in a Gemfile and let bundler handle the
# dependencies for you.
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

More about the two included programs `analysis` and `web` later.

### Setup a Config File

You will need to create a directory to store the `sqa` data and a configuration file.  You can start by doing this:

```ruby
gem install sqa
mkdir ~/Documents/sqa_data
sqa --data-dir ~/Documents/sqa_data --dump-config ~/.sqa.yml
```

By default `SQA` looks for a configuration file named `.sqa.yml` in the current directory.  If it does not find one there it looks in the home directory.  You can use the `--config` CLI option to specify a path to your custom config file name.

You can have multiple configurations and multiple data directories.

You can also have one data directory and multiple portfolio and trades files within that single directory.

### AlphaVantage

`SQA` makes use of the `AlphaVantage` API to get some stock related information.  You will need an API key in order to use this functionality.  They have a free rate limited API key which allows 5 accesses per second; total of 100 accesses in a day.  If you are doing more than that you are not playing an ought to purchase one of there serious API key plans.

[https://www.alphavantage.co/](https://www.alphavantage.co/)

Put your API key in the system environment variable `AV_API_KEY`

<!-- TODO: why is it not part of the configuration?  ought to be. -->


### TradingView

**Not currently implemented** but seriously considering using [TradingView](http://tradingview.com) capabilities.  If I do choose to use these capabilities you will need your own API key or account or something.

Put your API key in the system environment variable `TV_API_KEY`

<!-- TODO: why is it not part of the configuration?  ought to be. -->

I kinda like their Terms of Use.  I've started crafting an [SQA Terms of Use](docs/terms_of_use.md) document based on theirs.  I specifically like sections 7 and 8.

### Yahoo Finance

The finance.yahoo.com website no longer supports an API.  To get information from this website you must scrape it.  That is how historical / receint stock prices are being obtained in the DataFrame::YahooFinance class.  I do not like doing this and do not necessarily recommend using YahooFinance as a source for stock price data.

In the SQA::Stock class the default source is AlphaVantage which has its own limitations.

This is not to say that finance.yahoo.com has no use.  In fact is is the perfect place to go to manually download CSV files of historical stock price data.  When you do that through your browser, the CSV file will be placed in your default downloads directory.

To use this downed file within the SQA environment it must be moved into your `SQA.`data_dir` with a filename that is all lowercase.  The filename must be the stock's symbol with a `.csv` extension.  For example if you downloaded the entire historical stock price data for Apple Computer (AAPL) the filename in the SQA.data_dir should be "aapl.csv"

You can manually go to the Yahoo Finance website at [https://finance.yahoo.com/quote/AAPL/history?p=AAPL](https://finance.yahoo.com/quote/AAPL/history?p=AAPL)


## Playing in IRB

You can play around in IRB with the SQA framework.


### With Stocks and Indicators

You will need some CSV files.  If you ask for a stock to which you have not existing historical price data in a CSV file, `SQA` can use either Alpha Vantage or Yahoo Finance to get some data.  I like Alpha Vantage better because it has a well defined and documented API.  Yahoo Finance on the other hand does not.  You can manually download historical stock price data from Yahoo Finance into you `sqa data directory`

Historical price data is kept in the `SQA.data_dir` in a CSV file whose name is all lowercase.  If you download the CSV file for the stock symbol "AAPL" it should be saved in you `SQA.data_dir` as `aapl.csv`

#### Get Historical Prices

Go to [https::/finance.yahoo.com](https::/finance.yahoo.com) and down some historical price data for your favorite stocks.  Put those CSV files into the `SQA.data_dir`.

You may need to create a `portfolio.csv` file or you may not.

<!-- TODO: Add a section on how to create a portfolio fCSV file -->

The CSV files will be named by the stock's ticker symbol as lower case.  For example: `aapl.csv`

### Playing in the IRB - Setup

```ruby
require 'sqa'
require 'sqa/cli'

# TODO: Is this still true after the dry-cli integration?
#
# You can pass a set of CLI options in a String
SQA.init "-c ~/.sqa.yml"

# If you have an API key for AlphaVantage you can create a new
# CSV file, or update an existing one.  Your key MUST be
# in the system environment variable AV_API_KEY
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
ap ss.strategies #=>∑
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

## Included Program Examples

<!-- TODO: What is the name of these things?  From the help text they are called commands.  They are treated in the code base as a class under the SQA module.  Its easy to change the CLI help text to call these programs rather than commands. -->

There are at least two included programs that make use of the `SQA` library.

<!-- TODO: These kinds of things need to be in their own repository. -->

<!-- TODO: Need to complete the API for invoking one of these "programs" from the sqa cli. -->

### Analysis

Does an analysis of a portfollio of stocks.

### Web

Provides a browser-based interface to some stuff.

## Predicted FAQ

    What is the purpose of the SQA project? The madbomber/sqa project is a set of tools for running technical analysis on a stock portfolio. It's intended as a learning tool to help understand stock market analysis. It's not intended for real-world trading or financial use.

    How do I install and use SQA? You can install the gem by running gem install sqa or adding gem 'sqa' to your Gemfile and running bundle install. The project can be used from the command line or as a library in your own application. More details can be found in the README.md file.

    What technical indicators does SQA support? The project includes a variety of technical indicators such as Average True Range, Bollinger Bands, Candlestick Patterns, Donchian Channel, Double Top Double Bottom Pattern, Exponential Moving Average, Fibonacci Retracement, Head and Shoulders Pattern, Elliott Wave Theory, Market Profile Analysis, Mean Reversion, Momentum, Moving Average Convergence Divergence, Peaks and Valleys, Predict Next Value, Relative Strength Index, Simple Moving Average, and Stochastic Oscillator.

    What data sources does SQA support? The project supports data from AlphaVantage and Yahoo Finance. You will need an API key for AlphaVantage to use this functionality.

    What are the risks of using SQA for real-world trading? The madbomber/sqa project is intended as a learning tool and is not reliable for any kind of mission-critical financial use. The BUY/SELL signals that it generates should not be taken seriously. If you lose money in the stock market as a result of using this library, the project is not responsible.

    Can I contribute to the SQA project? Yes, contributions are welcome. You can submit bug reports and pull requests on the GitHub repository.

    What license does SQA use? The project is available as open source under the terms of the MIT License.

    What is the current state of the project? The project is a work in progress. The developer is experimenting with different gems to support various functionalities. Some features may not be fully implemented or may need further refinement.


## Other Similar Projects

There are several other (prehaps more mature) projects and libraries that provide similar capabilities to the SQA. Here are a few examples:

    TA-Lib (Technical Analysis Library): This is a popular open-source software library that provides tools for technical analysis of financial markets. It includes over 150 functions for various types of analysis including pattern recognition, moving averages, oscillators, and more. It's available in several programming languages including Python, Java, Perl, and more. TA-Lib

    Pandas TA: This is a Python library that provides comprehensive functionalities for technical analysis. It's an extension of the popular data analysis library Pandas and includes a wide range of financial indicators. Pandas TA

    Backtrader: This is a Python library for backtesting trading strategies. It supports a wide range of trading concepts including trading calendars, multiple data feeds, and order execution types. Backtrader

    PyAlgoTrade: This is another Python library for backtesting stock trading strategies. It supports Yahoo! Finance, Google Finance, and others as data sources, and has a focus on simplicity and flexibility. PyAlgoTrade

    QuantLib: This is a comprehensive software framework for quantitative finance, it provides tools for many aspects of quantitative finance including trading and risk management, financial instruments, mathematics, numerical methods, and model calibration. QuantLib

    zipline: This is a Python library for algorithmic trading. It allows strategy testing and supports live-trading and backtesting, and includes a number of financial computations to aid in trading decisions. zipline


## Contributing

I can always use some help on this stuff.  Got an idea for a new indicator or strategy?  Want to improve the math?  Make the signals better?  Let's collaborate!

Bug reports and pull requests are welcome on GitHub at https://github.com/MadBomber/sqa.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
