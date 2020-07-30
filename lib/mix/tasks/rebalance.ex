defmodule Mix.Tasks.Rebalance do
  use Mix.Task

  @shortdoc "Rebalance your portfolio."
  def run(_) do
    {:ok, _started} = Application.ensure_all_started(:httpoison)
    Rebalancer.rebalance()
  end
end
