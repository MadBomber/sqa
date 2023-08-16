# DataFrame (DF)

A common way to handling data is good.  Having multiple ways to import and export datasets is good.  Originally SQA::Datastore was intended to provide this functionality but creating that capability took away from the key focs of this project.

Daru was chosen to fill the gap.  The Daru::Vector and Daru::DataFrane classes offer a good abstraction with multiple import and export formats.

Daru is part of the SciRuby collection.  Both Daru and SciRuby are a little out of date.

* https://github.com/SciRuby/daru
* https://github.com/SciRuby

There will be Daru extensions and patches made to adapt it to the specific needs of SQA.

Frankly, Ruby has lost the battle to Python w/r/t data analysis.  The Python equivalent library to Daru is Pandas.  It is actively maintained.  There is a Ruby gem that uses PyCall to access Pandas but it is a few years out of date with open issues.

## Creating a DataFrame from a CSV File

A common activity is to use financial websites such as https://finance.yahoo.com to download historical price data for a stock.

Here is how to create a DataFrame from a CSV file downloaded from Finance.yahoo.com ...

```ruby
df = Daru::DataFrame.from_csv('aapl.csv')
```

The Daru::DataFrame class can be created from many different sources including an ActiveRecord relation -- e.g. you can get you data from a database.

## Using a DataFrame

The column names for a DataFrame are String objects.  To get an Array of the column names do this:

```ruby
df.vectors.to_a
  #=> ["Date", "Open", "High", "Low", "Close", "Adj Close", "Volume"]
```

To get an Array of any specific column do this:

```ruby
df.vectors["The Column Name"].to_a
# where "Any Column Name" could be "Adj Close"

```

You can of course use the `last()` method to constrain your Array to only those entries that make sense during your analysis.  Daru::DataFrame supposts both the `first` and `last` methods as well.  You can use them to avoid using any more memory in your Array than is needed.

```ruby
df.vectors["The Column Name"].last(14).to_a
  # This limits the size of the Array to just the last 14 entries in the DataFrame
```

## Renaming the Columns

You can rename the columns to be symbols.  Doing this allows you to use the column names as methods for accessing them in the DataFrame.

```ruby
old_names = df.vectors.to_a
  #=> ["Date", "Open", "High", "Low", "Close", "Adj Close", "Volume"]

new_names = {} # Hash where key is old name, value is new name
  #=> {}

df.vectors.each_entry {|old_name| new_names[old_name] = old_name.downcase.gsub(' ','_').to_sym}

new_names
  #=>
{"Date"=>:date,
 "Open"=>:open,
 "High"=>:high,
 "Low"=>:low,
 "Close"=>:close,
 "Adj Close"=>:adj_close,
 "Volume"=>:volume}


df.rename_vectors(new_names)
  #=> #<Daru::Index(7): {date, open, high, low, close, adj_close, volume}>

df.vectors
  #=> #<Daru::Index(7): {date, open, high, low, close, adj_close, volume}>

# Now you can use the symbolized column name as a method to select that column
df.volume.last(14).volume
  #=>
#<Daru::Vector(14)>
              volume
     10741  45377800
     10742  37283200
     10743  47471900
     10744  47460200
     10745  48291400
     10746  38824100
     10747  35175100
     10748  50389300
     10749  61235200
     10750 115799700
     10751  97576100
     10752  67823000
     10753  60378500
     10754  54628800
```





## Stats on a DataFrame

Daru provides some basic tools for the analysis of data stored in a DataFrame.  There are too many to cover at this time.  Here is a simple example:

```ruby
df.last(14)['Adj Close'].minmax
  #=> [177.970001, 196.449997]

# You cab cgabge the order of operations ...
df['Adj Close'].last(14).minmax
  #=> [177.970001, 196.449997]

# Get a summary report ...
puts df['Adj Close'].last(14).minmax
```
<pre>
= Adj Close
  n :14
  non-missing:14
  median: 192.66500100000002
  mean: 188.7521
  std.dev.: 7.4488
  std.err.: 1.9908
  skew: -0.4783
  kurtosis: -1.7267
</pre>

## Bacon in the Sky

```ruby
puts df.ai("when is the best time to buy a stock?")
```
The best time to buy a stock is subjective and can vary depending on individual goals, investment strategies, and risk tolerance. However, there are a few general principles to consider:

1. Valuation: Look for stocks trading at a reasonable or discounted price compared to their intrinsic value. Conduct fundamental analysis to assess a company's financial health, growth prospects, and competitive advantage.

2. Market Timing: Trying to time the market perfectly can be challenging and is often unpredictable. Instead, focus on buying stocks for the long term, considering the company's potential to grow over time.

3. Diversification: Avoid investing all your funds in a single stock or industry. Diversifying your portfolio across various sectors can help reduce risk and capture different opportunities.

4. Patient approach: Practice patience and avoid making impulsive decisions. Regularly monitor the stock's performance, industry trends, and market conditions to make informed choices.

5. Considerations: Take into account any upcoming events that may impact a stock's price, such as earnings announcements, mergers and acquisitions, regulatory changes, or macroeconomic factors.

It's important to note that investing in stocks carries inherent risks, and seeking guidance from financial professionals or conducting thorough research is recommended.  Don't ever listen to what an AI has to say about the subject.  We are all biased, error prone, and predictability uninformed on the subject.


```ruby
puts df.ai("Yes; but, should I buy this stock now?")
```
Consulting the magic eight ball cluster.... The future looks cloudy.  You should have bought it 14 days ago when I told you it was on its way up!  Do you ever listen to me?  No!  I slave over these numbers night and day.  I consult the best magic eight ball sources available.  What do I get for my efforts?  Nothing!







