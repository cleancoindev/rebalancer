defmodule Mix.Tasks.ExchangeInfo do
  use Mix.Task

  @shortdoc "Rebalance your portfolio."
  def run(_) do
    {:ok, _started} = Application.ensure_all_started(:httpoison)

    ExBinance.Public.exchange_info()
    |> IO.inspect()
  end
end
