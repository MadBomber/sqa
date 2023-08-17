# Trading Strategies

A **strategy** is implemented as a class within the namespace of SQA::Strategy -- see the file lib/sqa/strategy/random.rb as an example.  All strategy classes should have a class method **trade** which is the primary entry point into the strategy.  The class can be extended using the SQA::Strategy::Common module which adds common class methods such as **trade_against** and **desc**

## The **trade** Class Method

The method accepts a single parameter called a vector.  The vector parameter is an object that contains the information required by the strategy in order to make a recommendation.  In the examples provided this object is an OpenStruct.  You can either follow this pattern or use your own; however, at this time only one parameter is allowed for the trade method.

## The **trade_against** Class Method

If **trade** is consistently wrong many more times than it is right, don't throw it out.  Just start using the **trade_against** class method instead.  This method takes the recommendation of the **trade** class method and suggests the opposite.

## The **desc** Class Method

You can document your strategy in a markdown formatted file.  The **desc** class method will look for the filename in the same directory as the strategy file.  This is typically in the lib/sqa/strategy directory.

The **desc** class method will find the markdown file and return its contents as a String so that you can do with it as you please.

## Example Strategies

The follow examples are provided:

* ema.rb
* mp.rb
* mr.rb
* random.rb
* rsi.rb
* sma.rb

## Usage

Tge SQA::Strategy class manages an Array of trading strategies.  You can add to the Array multiple strategies like this:

```ruby
require 'sqa'
ss = SQA::Strategy.new
ss.add SQA::Strategy::Random.method(:trade)
ss.add SQA::Strategy::SMA.method(:trade)
ss.add SQA::Strategy::EMA
```

Note that if your primary entry point to the trading strategy class is **trade** then the parameter to the **add** function does not have to include the ".method(:entry_point)" -- just use the class name by itself.  If you do not use **trade** as as class method in you strategy class, then the **trade_against** method added by the SQA::Strategy::Common module will not work.

If you want to evaluate the **trade_against** class method in a strategy then you must the "ss.add SQA::Strategy::Random.method(:trade_against)" pattern.

Then for any specific stock create your vector object that contains all the information that the trading strategies need in order to make their recommendations.  Once you have you vector you can then **execute** the Array of strategies.

```ruby
vector = ...
result = ss.execute(vector)
```

**result** will be an Array of recommendations from the different strategies on whether to :bur, :sell or :hold.

