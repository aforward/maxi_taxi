defmodule MaxiTaxi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @dev Mix.env() == :dev

  def start(_type, _args) do
    children =
      [
        {Cluster.Supervisor, [libcustomer_configs(), [name: MyApp.ClusterSupervisor]]},
        MaxiTaxi.TaxiLocationsDatabase,
        {Registry, name: MaxiTaxi.TaxiRegistry, keys: :unique},
        {DynamicSupervisor, name: MaxiTaxi.TaxiSupervisor, strategy: :one_for_one}
      ] ++ simulated_taxis()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MaxiTaxi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp simulated_taxis do
    if @dev do
      Enum.map(1..10, fn _ -> MaxiTaxi.SimulatedTaxi end)
    else
      []
    end
  end

  defp libcustomer_configs do
    topologies = [
      maxi_taxi: [
        strategy: Cluster.Strategy.Epmd,
        config: [hosts: [:"maxi@127.0.0.1", :"maxi2@127.0.0.1"]],
      ]
    ]
  end
end
