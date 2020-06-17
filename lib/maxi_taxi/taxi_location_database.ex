defmodule MaxiTaxi.TaxiLocationsDatabase do
  use GenServer

  @table __MODULE__

  def child_spec(arg) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [arg]}}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_) do
    :ets.new(
      @table,
      [:public, :named_table, {:write_concurrency, true}, {:read_concurrency, true}]
    )

    {:ok, nil}
  end

  @type taxi :: String.t()
  @type lat :: float()
  @type lon :: float()
  @type timestamp :: float()
  @type location :: {lat(), lon()}

  @spec update(taxi(), location()) :: :ok
  def update(taxi, location) do
    now = ts()
    update_local(taxi, location, now)
    Node.list()
    |> Enum.each(fn n ->
      :rpc.call(n, MaxiTaxi.TaxiLocationsDatabase, :update_local, [taxi, location, now], 2000)
    end)
  end

  @spec update_local(taxi(), location(), timestamp()) :: :ok
  def update_local(taxi, location, updated_at) do
    now = ts()
    if (now - updated_at < 2000) do
      :ets.insert(@table, {taxi, location, updated_at})
    end
    :ok
  end

  defp ts(), do: DateTime.utc_now() |> DateTime.to_unix()

  @spec fetch(taxi()) :: {:ok, location()} | :no_known_location
  def fetch(taxi) do
    case :ets.lookup(@table, taxi) do
      [] -> :no_known_location
      [{^taxi, location, _ts}] -> {:ok, location}
    end
  end

  def all() do
    :ets.tab2list(@table)
  end

  @spec find(location()) :: {:ok, taxi()} | :no_taxi_found
  def find({search_lat, search_lon}) do
    # just using euclidean distance here because it's simple. This works at the equator but will work less well the nearer one gets to the poles.
    # filter for all taxis within 0.01 degree (approx 1.1km at the equator) and then sort on distance

    match_spec = [
      {
        {:"$1", {:"$2", :"$3"}},
        [
          {:is_float, :"$2"},
          {:is_float, :"$3"},
          {:is_integer, :"$4"},
          {:>, :"$2", search_lat - 0.01},
          {:<, :"$2", search_lat + 0.01},
          {:>, :"$3", search_lon - 0.01},
          {:<, :"$3", search_lon + 0.01}
        ],
        [:"$_"]
      }
    ]

    case :ets.select(@table, match_spec) do
      [] ->
        :no_taxi_found

      locations ->
        {taxi, _coords} =
          Enum.sort_by(locations, fn {_taxi, {lat, lon}, _updated_at} ->
            (:math.pow(lat - search_lat, 2) + :math.pow(lon - search_lon, 2))
            |> :math.sqrt()
          end)
          |> hd()

        {:ok, taxi}
    end
  end

  def clear() do
    :ets.delete_all_objects(@table)
  end
end
