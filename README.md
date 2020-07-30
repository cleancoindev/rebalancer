# Rebalancer

Cryptocurrency automatic portfolio rebalancing bot.

## Config

Using config.exs file:

```
    coins: Must be a list of string coins. ex: ["BNB", "ETH"]
    stake: Must be a string. ex: "BTC" 
    threshold: Must be a string. ex: "0.03
    times: Must be an array of times: [~T[06:00:00.000000], ~T[16:00:00.000000]]
```


You can configure it using the following enviroment variables:

```
REBALANCER_COINS
REBALANCER_STAKE
REBALANCER_THRESHOLD
BINANCE_API_KEY
BINANCE_API_SECRET
```

## Usage

- Start the project with `iex -S mix` it will rebalance based on the `times` configuration
- Use `mix rebalance` to trigger a manual rebalacing.

## RoadMap

- Tests
- Portfolio Snapshots
