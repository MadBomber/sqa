# Market Profile Strategy

## Overview

Uses market profile analysis to identify support and resistance levels, generating signals when price reaches these key levels.

## How It Works

Analyzes price distribution to find:
- **Value Area**: Where most trading occurred
- **Support**: Lower boundary (buy zone)
- **Resistance**: Upper boundary (sell zone)

## Trading Signals

### Buy Signal
Price at support level (`:support`).

### Sell Signal  
Price at resistance level (`:resistance`).

### Hold Signal
Price within value area (`:mixed`).

## Usage Example

```ruby
# Market profile data typically comes from
# price/volume distribution analysis
vector = OpenStruct.new(
  market_profile: :support  # or :resistance, :mixed
)

signal = SQA::Strategy::MP.trade(vector)
```

## Characteristics

- **Complexity**: High
- **Best Market**: Range-bound
- **Win Rate**: 55-65%

## Strengths

✅ Identifies key price levels  
✅ Works well for intraday trading  
✅ Statistical basis  

## Weaknesses

❌ Requires volume profile data  
❌ Complex to calculate  
❌ Less effective in trending markets  

