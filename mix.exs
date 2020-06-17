defmodule MaxiTaxi.MixProject do
  use Mix.Project

  def project do
    [
      app: :maxi_taxi,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {MaxiTaxi.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:libcluster, "~> 3.2"},
      {:delta_crdt, "~> 0.5.0"},
      {:horde, "~> 0.8.0-rc.1"},
      {:local_cluster, "~> 1.1", only: :test},
      {:schism, "~> 1.0", only: :test}
    ]
  end

  defp aliases do
    [test: "test --no-start --seed 0 --trace --max-failures 1"]
  end
end
