defmodule Rebalancer.Helper do
  alias Decimal, as: D

  def avg_price(asset, stake) when asset == stake, do: 1

  def avg_price(asset, stake) do
    {:ok, %{asks: [[ask, _] | _], bids: [[bid, _] | _]}} =
      ExBinance.Public.depth(asset <> stake, 10)

    bid
    |> D.add(ask)
    |> D.div(2)
  end

  def sell_order(symbol, quantity, price, credentials) do
    ExBinance.Private.create_order(symbol, "SELL", "LIMIT", quantity, price, "GTC", credentials)
  end

  def buy_order(symbol, quantity, price, credentials) do
    ExBinance.Private.create_order(symbol, "BUY", "LIMIT", quantity, price, "GTC", credentials)
  end

  def pair_infos(symbol, stake, exchange_infos),
    do: Enum.find(exchange_infos.symbols, &(&1["symbol"] == symbol <> stake))

  @spec get_balance(any, any) :: any
  def get_balance(balances, coin), do: Enum.find(balances, &(&1["asset"] == coin))

  def amount_to_string(amount, stepSize) do
    D.sub(amount, D.rem(amount, D.new(stepSize)))
    |> D.reduce()
    |> D.to_string(:normal)
  end

  def price_to_string(avg_price, tickSize) do
    D.sub(avg_price, D.rem(avg_price, tickSize))
    |> D.reduce()
    |> D.to_string(:normal)
  end

  def buy(symbol, stake, target, free, avg_price, lot_size, price_filter, credentials) do
    amount =
      D.sub(target, free)
      |> D.div(avg_price)
      |> amount_to_string(D.new(lot_size["stepSize"]))

    avg_price = price_to_string(avg_price, D.new(price_filter["tickSize"]))

    if D.cmp(amount, lot_size["minQty"]) != :lt,
      do: buy_order(symbol <> stake, amount, avg_price, credentials) |> IO.inspect()

    IO.inspect("BUY: #{symbol} #{amount} #{avg_price}")
  end

  def sell(symbol, stake, target, free, avg_price, lot_size, price_filter, credentials) do
    amount =
      D.sub(free, target)
      |> D.div(avg_price)
      |> amount_to_string(D.new(lot_size["stepSize"]))

    avg_price = price_to_string(avg_price, D.new(price_filter["tickSize"]))

    if D.cmp(amount, lot_size["minQty"]) != :lt do
      sell_order(symbol <> stake, amount, avg_price, credentials)
      |> IO.inspect()

      IO.inspect("SELL: #{symbol} #{amount} #{avg_price}")
    else
      IO.inspect("COULD NOT SELL,#{symbol} #{amount} #{avg_price}  minQty: #{lot_size["minQty"]}")
    end
  end
end
