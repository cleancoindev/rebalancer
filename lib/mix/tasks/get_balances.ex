defmodule Mix.Tasks.GetBalances do
  use Mix.Task

  @shortdoc "Rebalance your portfolio."
  def run(_) do
    {:ok, _started} = Application.ensure_all_started(:httpoison)

    credentials = %ExBinance.Credentials{
      api_key: Application.get_env(:ex_binance, :api_key),
      secret_key: Application.get_env(:ex_binance, :secret_key)
    }

    {:ok, %{balances: balances}} = ExBinance.Private.account(credentials)
    IO.inspect(balances)
  end
end
