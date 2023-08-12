# Requirements

... otherwise know as what I want to do.  Some people would call it a roadmap; but, where I'm going "we don't need no stinking roads!"

Yes, test driven development (TDD) is important.  There is a place for TDD.  Its not in prototyping.  The prototype is used to figure out what the requirements are.  Once you have a prototype then you have requirements.  With requirements come contracts for APIs.  The contracts drive the test specifications which in turn drives the design.

So what is it that I want to do?

* collect technical analysis indicators to apply to a stock or a set of stocks.
* define an abstraction for a stock
* evaluate different trading strategies.
* make billions on the sock market - if you have kids you know what the sock market is.
* play around with some interesting gems
* evaluate Ruby 3.3 YJIT against Crystal
* look at carious ways to support plugin components
* learn something about options trading in risk mitigation for security trades

## Making this thing an Application Framework

* using ActiveRecord with initial models of Stock, Portfolio and Activity

	- Portfolio has many stocks with FK: ticker
	- Sotkc has many activities with FK: ticker
	- Activity has unique constraint on (ticker, date)

* using gem csv_importer to bring in data to load into the various tables
* using sqlite3 because I have limited resources for rdbms

## finance.yahoo.com API

v7 is used to download historical data as CSV.  It requires a cookie.

v8 gets some company info and stock prices in JSON. It might require a cookie as well

Most reliable way of getting data is the scrape the website.  The gem financial_data_pull attempts to do it but it is too old.


## Extract Indicators

After sleeping on it, I think the original plan with the fin_tech gem is a better idea for how to package the indicators.  I'm going to keep the name FinTech for now while I think of something better.  These are indicators; but I want them to be class-level methods with established contracts in their API.
