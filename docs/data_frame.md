# DataFrame (DF)

TODO: Review the Ruby code to make sure that it still works.

A common way to handling data is good.  Having multiple ways to import and export datasets is good.  Originally SQA::Datastore was intended to provide this functionality but creating that capability took away from the key focus of this project.

Rpver was chosen )as of v0.0.16) to fill the gap - replacing Daru.

There may be Rover extensions and patches made to adapt it to the specific needs of SQA.

Frankly, Ruby has lost the battle to Python w/r/t data analysis.


## Creating a DataFrame from a CSV File

A common activity is to use financial websites such as https://finance.yahoo.com to download historical price data for a stock.

Here is how to create a DataFrame from a CSV file downloaded from Finance.yahoo.com ...

```ruby
df = SQA::DataFrame.load('aapl.csv')
```

The SQA::DataFrame object can be created from many different sources including an ActiveRecord relation -- e.g. you can get you data from a database.

## Using a DataFrame

The column names for a DataFrame are String or Symbol objects.  To get an Array of the column names do this:

```ruby
df.vectors.to_a
  #=> ["Date", "Open", "High", "Low", "Close", "Adj Close", "Volume"]
```

To get an Array of any specific column do this:

```ruby
df.vectors["The Column Name"].to_a
# where "Any Column Name" could be "Adj Close"

```

You can of course use the `last()` method to constrain your Array to only those entries that make sense during your analysis.  SQA::DataFrame supports both the `first` and `last` methods as well.  You can use them to avoid using any more memory in your Array than is needed.

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

df.vectors

# Now you can use the symbolized column name as a method to select that column
df.volume.last(14).volume
```

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

