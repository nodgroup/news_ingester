defmodule NewsIngester.AACrawler do
  use GenServer
  @moduledoc false

  ## Client API

  @doc """
  Starts GenServer
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Searches news and parses results
  """
  def search(server) do
    GenServer.call(server, :search)
  end

  ## Server Callbacks

  @doc """
  Initializes GenServer
  """
  def init(_opts) do
    {:ok, %{}}
  end

  def handle_call(:search, _from, state) do
    endpoint =
      NewsIngester.get_config(:a_a_base_endpoint) <> NewsIngester.get_config(:a_a_search_endpoint)

    filter = NewsIngester.AAHelper.generate_search_filter()
    header = NewsIngester.AAHelper.generate_auth_header()
    response = HTTPoison.post(endpoint, filter, header)
    {:reply, response, state}
  end

  @doc """
  Default fallback for calls
  """
  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  @doc """
  Default fallback for casts
  """
  def handle_cast(_msg, state) do
    {:noreply, state}
  end
end
