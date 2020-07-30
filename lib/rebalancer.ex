defmodule Rebalancer do
  @moduledoc """

  Cryptocurrency automatic portfolio rebalancing bot.

  ## Configuration:

  In your config.exs file add:
  ```
  config :rebalancer,
    coins: ["ETH", "LTC"],
    stake: "BTC",
    threshold: "0.03",
    times: [~T[06:00:00.000000]]

  config :ex_binance,
    domain: "api.binance.com",
    api_key: "XXXXX",
    secret_key: "XXXXX"
  ```

  coins: are the coins you would like to use.
  stake is the base currency used.
  threshold is the threshold to trigger a rebalance
  times is an array of hours you would like the bot to run the rebalance
  """
  defstruct [
    :credentials,
    :coins,
    :stake,
    :threshold,
    :exchange_infos,
    :balances,
    :total_balance,
    :target,
    :sell_threshold,
    :buy_threshold
  ]

  import Rebalancer.Helper
  alias Decimal, as: D
  require Logger

  def rebalance() do
    Logger.info("Start rebalancing")
    %__MODULE__{}
    |> get_config()
    |> get_credentials()
    |> get_exchange_infos()
    |> cancel_all_orders()
    |> get_balances()
    |> convert_to_stake_balances()
    |> total_balance()
    |> target()
    |> thresholds()
    |> execute()
    Logger.info("Done rebalancing")
  end

  def get_config(state) do
    coins = Application.get_env(:rebalancer, :coins)
    coins = if is_binary(coins), do: Jason.decode!(coins), else: coins

    %{
      state
      | coins: coins,
        stake: Application.get_env(:rebalancer, :stake),
        threshold: Application.get_env(:rebalancer, :threshold) |> D.new()
    }
  end

  def get_credentials(state) do
    credentials = %ExBinance.Credentials{
      api_key: Application.get_env(:ex_binance, :api_key),
      secret_key: Application.get_env(:ex_binance, :secret_key)
    }

    %{state | credentials: credentials}
  end

  def get_exchange_infos(state) do
    {:ok, exchange_infos} = ExBinance.Public.exchange_info()
    %{state | exchange_infos: exchange_infos}
  end

  def cancel_all_orders(%{coins: coins, stake: stake, credentials: credentials} = state) do
    Enum.each(coins, fn coin ->
      ExBinance.Private.cancel_all_orders(coin <> stake, credentials)
    end)

    state
  end

  def get_balances(%{credentials: credentials, coins: coins, stake: stake} = state) do
    {:ok, %{balances: balances}} = ExBinance.Private.account(credentials)

    balances =
      balances
      |> Enum.filter(&(&1["asset"] in coins or &1["asset"] == stake))

    %{state | balances: balances}
  end

  def convert_to_stake_balances(%{stake: stake, balances: balances} = state) do
    balances =
      balances
      |> Enum.map(fn %{"free" => free, "asset" => asset, "locked" => locked} = balance ->
        Task.async(fn ->
          avg_price = avg_price(asset, stake)

          %{balance | "free" => D.mult(avg_price, free), "locked" => D.mult(avg_price, locked)}
          |> Map.put("avg_price", avg_price)
        end)
      end)
      |> Enum.map(&Task.await/1)

    %{state | balances: balances}
  end

  def total_balance(%{balances: balances} = state) do
    total_balance =
      Enum.reduce(balances, D.new(0), fn %{"free" => free}, acc ->
        D.add(acc, free)
      end)

    %{state | total_balance: total_balance}
  end

  def target(%{total_balance: total_balance, balances: balances} = state) do
    target =
      total_balance
      |> D.div(length(balances))

    %{state | target: target}
  end

  def thresholds(%{target: target, threshold: threshold} = state) do
    amount = D.mult(target, threshold)

    sell_threshold = D.add(target, amount)
    buy_threshold = D.sub(target, amount)

    %{
      state
      | sell_threshold: sell_threshold,
        buy_threshold: buy_threshold
    }
  end

  def execute(%{
        coins: coins,
        stake: stake,
        credentials: credentials,
        exchange_infos: exchange_infos,
        balances: balances,
        target: target,
        sell_threshold: sell_threshold,
        buy_threshold: buy_threshold
      }) do
    Enum.each(coins, fn symbol ->
      %{"free" => free, "avg_price" => avg_price} = get_balance(balances, symbol)

      %{"baseAssetPrecision" => precision, "filters" => filters} =
        pair_infos(symbol, stake, exchange_infos)

      lot_size = Enum.find(filters, &(&1["filterType"] == "LOT_SIZE"))
      price_filter = Enum.find(filters, &(&1["filterType"] == "PRICE_FILTER"))

      D.with_context(%{D.get_context() | precision: precision}, fn ->
        cond do
          D.cmp(free, buy_threshold) == :lt ->
            buy(symbol, stake, target, free, avg_price, lot_size, price_filter, credentials)

          D.cmp(free, sell_threshold) == :gt ->
            sell(symbol, stake, target, free, avg_price, lot_size, price_filter, credentials)

          true ->
            nil
        end
      end)
    end)
  end
end
