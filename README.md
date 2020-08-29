# Rebalancer

Cryptocurrency automatic portfolio rebalancing bot.

## Config

Using config.exs file:

```
    coins: Must be a list of string coins. ex: {"BNB": 1, "ETH": 3}
    stake: Must be a string. ex: "BTC" 
    stake_exposure: Let you choose the exposure to your stake. ex: 1
    threshold: Must be a string. ex: "0.03
    times: Must be an array of times: [~T[06:00:00.000000], ~T[16:00:00.000000]]
```

*time can be if you use `mix rebalance`*


`{"COIN": EXPOSURE}` let you choose how much exposure you want to a coin, ex: {"BNB": 1, "ETH": 3} will hold 3 times more ETH than BNB. 

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
