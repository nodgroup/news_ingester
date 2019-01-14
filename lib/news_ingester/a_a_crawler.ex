defmodule NewsIngester.AACrawler do
  use GenServer
  @moduledoc false

  @doc """
  Crawler logic
  """
  def crawl() do
    server = NewsIngester.AACrawler
    results = search(server)

    results
    |> Enum.each(fn result -> process_results(server, result) end)
  end

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

  @doc """
  Processes crawler results
  """
  def process_results(server, element) do
    GenServer.cast(server, {:process_results, element})
  end

  ## Server Callbacks

  @doc """
  Initializes GenServer
  """
  def init(_opts) do
    {:ok, %{}}
  end

  def handle_call(:search, _from, state) do
    url = NewsIngester.AAHelper.generate_url(:a_a_search_path)
    filter = NewsIngester.AAHelper.generate_search_filter()
    header = NewsIngester.AAHelper.generate_auth_header()
    {:ok, response} = HTTPoison.post(url, filter, header)

    {:ok, body} =
      response.body
      |> Poison.Parser.parse()

    if body["response"]["success"] == false do
      {:reply, :error, state}
    else
      result =
        Enum.reduce(
          body["data"]["result"],
          %{},
          fn result, acc ->
            title = String.trim(result["title"])
            id = [result["id"]]
            value = Map.get(acc, title)

            if value == nil do
              Map.put(acc, title, id)
            else
              Map.put(acc, title, value ++ id)
            end
          end
        )

      {:reply, result, state}
    end
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
