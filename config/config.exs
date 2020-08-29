import Config

config :rebalancer,
  coins: System.get_env("REBALANCER_COINS"),
  stake: System.get_env("REBALANCER_STAKE"),
  stake_exposure: (System.get_env("REBALANCER_STAKE_EXPOSURE") || "1") |> String.to_integer(),
  threshold: System.get_env("REBALANCER_THRESHOLD"),
  times: [~T[06:00:00.000000]]

config :ex_binance,
  domain: "api.binance.com",
  api_key: System.get_env("BINANCE_API_KEY"),
  secret_key: System.get_env("BINANCE_API_SECRET")

if File.exists?("config/#{Mix.env()}.exs") do
  import_config "#{Mix.env()}.exs"
end
