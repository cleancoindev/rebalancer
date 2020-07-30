defmodule Rebalancer.Server do
  @moduledoc """
  Documentation for `Rebalancer.Server`.
  """
  use GenServer
  @rebalance_times Application.get_env(:rebalancer, :times)

  def init(_) do
    Process.send_after(self(), :run, 1000)

    {:ok, nil}
  end

  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  def handle_info(:run, state) do
    reschedule()

    Rebalancer.rebalance()
    {:noreply, state}
  end

  def reschedule do
    now = Time.utc_now()

    delay =
      Enum.map(@rebalance_times, fn time ->
        time = Time.diff(time, now, :millisecond)

        if time < 0 do
          time + 24 * 3_600_000
        else
          time
        end
      end)
      |> Enum.min()

    Process.send_after(__MODULE__, :run, delay)
  end
end
