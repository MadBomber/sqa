# Technical Market Analysis: Understanding the True Strength Index (TSI)

The **True Strength Index (TSI)** is a technical momentum oscillator used to identify trends and reversals primarily in the price of a security. It is not directly related to the Relative Strength Index (RSI), although both are momentum indicators.

## How TSI is Calculated

The TSI formula is based on double smoothing of price changes:

1. **Calculate the Price Momentum**:
   - Determine the daily price change: Current price minus previous price.
   - Create a 25-period Exponential Moving Average (EMA) of price changes (this period can vary based on the trader's preference).

2. **Calculate the Absolute Price Momentum**:
   - Calculate the absolute value of the daily price change.
   - Create a 25-period EMA of the absolute price changes.

3. **Apply a Secondary Smoothing**:
   - Calculate a 13-period EMA of the 25-period EMA of price changes.
   - Calculate a 13-period EMA of the 25-period EMA of the absolute price changes.

4. **The TSI Formula**:
   - TSI = 100 x (Double Smoothed Price Change / Double Smoothed Absolute Price Change)

The most common settings for the TSI are the 25-period EMA for initial smoothing and the 13-period EMA for the second smoothing. These periods can be adjusted to suit different trading styles and timeframes.

## How to Interpret TSI

- **Centerline Crossover**:
  - When the TSI crosses above the centerline (0), it is considered bullish.
  - When it crosses below the centerline, it is considered bearish.

- **Signal Line Crossover**:
  - Traders often add a signal line, which is an EMA of the TSI (commonly a 7-period EMA).
  - A bullish signal is generated when the TSI crosses above the signal line.
  - A bearish signal is generated when TSI crosses below the signal line.

- **Overbought / Oversold Conditions**:
  - The TSI can indicate overbought or oversold conditions. However, unlike RSI, there are no standard levels, such as 70 or 30, to indicate these conditions in TSI.
  - Traders often observe extreme levels or divergence with the price to identify possible reversals.

- **Divergences**:
  - Bullish divergence occurs if the price is making new lows while the TSI is failing to make new lows.
  - Bearish divergence occurs if the price is making new highs while the TSI is failing to make new highs.

The TSI can be a valuable tool in your technical analysis toolkit. It helps to smooth out the volatility inherent in the market and provides a clearer picture of the price momentum. As with any technical indicator, it is advisable to use the TSI in conjunction with other tools and analysis methods to confirm signals and make informed trading decisions.

