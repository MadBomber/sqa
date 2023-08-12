# Relative Strength Index (RSI)

This method takes in an array of historical prices for a stock and a period (the number of days to calculate the RSI over). It uses the `each_cons` method to iterate over a sliding window of closing prices and calculate the gains and losses for each window. Then, it calculates the average gain and average loss for the time period and uses these values to calculate the RSI. The method returns the RSI value for the given period.

* over_bought if rsi >= 70
* over_sold   if rsi <= 30
