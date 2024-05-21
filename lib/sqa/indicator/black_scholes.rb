# lib/sqa/indicator/black_scholes.rb


=begin
Refactored black_scholes method with meaningful parameter names:
=end




def black_scholes(
      option_type,          # a call ('c') or a put ('p')
      current_stock_price,  # The current price of the stock.
      strike_price,         # The strike price of the option.
      time_to_expiration,   # The time to expiration in years.
      risk_free_rate,       # The risk-free interest rate, expressed as a decimal.
      volatility            # The volatility of the stock's returns, also expressed as a decimal.
    )
  
  # Calculate the two components d1 and d2 used in the Black-Scholes formula
  numerator_component = Math.log(current_stock_price / strike_price) + (risk_free_rate + volatility * volatility / 2.0) * time_to_expiration
  denominator_component = volatility * Math.sqrt(time_to_expiration)
  d1 = numerator_component / denominator_component
  d2 = d1 - volatility * Math.sqrt(time_to_expiration)

  # Calculate the option price based on whether it's a call or put option
  if option_type == 'c'
    # Calculate the price of a European call option
    call_price = current_stock_price * normal_distribution(d1) - strike_price * Math.exp(-risk_free_rate * time_to_expiration) * normal_distribution(d2)
    return call_price
  elsif option_type == 'p'
    # Calculate the price of a European put option
    put_price = strike_price * Math.exp(-risk_free_rate * time_to_expiration) * normal_distribution(-d2) - current_stock_price * normal_distribution(-d1)
    return put_price
  else
    raise ArgumentError, "Invalid option type. Use 'c' for call or 'p' for put."
  end
end

def normal_distribution(x)
  # Implement the cumulative distribution function for a standard normal distribution
  (1.0 + Math.erf(x / Math.sqrt(2.0))) / 2.0
end

__END__

Stock volatility refers to the degree of variation of a trading price series over time. It indicates the risk or uncertainty about
changes in a stock's value.

Examples:
- High volatility: >30% annualized volatility means the stock price is highly unpredictable.
- Low volatility: <10% annualized volatility means the stock price is relatively stable.

To calculate volatility:
1. Compute the daily returns (percentage change in prices).
2. Calculate the standard deviation of these daily returns to get daily volatility.
3. Annualize the daily volatility by multiplying it by the square root of the number of trading days in a year (typically √252).

Your code example calculates the price of European options using the Black-Scholes model, where the `volatility` parameter
represents the stock's volatility, a crucial input for identifying the risk involved in the option's underlying asset.

