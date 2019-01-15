defmodule NewsIngester.AACrawler do
  use GenServer
  require Logger
  @moduledoc false

  ## Client API

  @doc """
  Crawler logic
  """
  def crawl do
    server = NewsIngester.AACrawler
    results = search(server)

    results
    |> Enum.each(fn result -> process_results(server, result) end)
  end

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
    # AA requires 500 ms wait time between each request
    :timer.sleep(500)

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

  def handle_cast({:process_results, element}, state) do
    _title = elem(element, 0)
    id = elem(element, 1)

    id
    |> Enum.each(fn e ->
      props = String.split(e, ":")
      type = Enum.at(props, 1)

      case type do
        "picture" ->
          get_document(e, type)

        "video" ->
          get_document(e, type)

        "text" ->
          get_document(e, type)

        _ ->
          Logger.error("Type not recognized: #{type}")
          nil
      end
    end)

    {:noreply, state}
  end

  @doc """
  Default fallback for casts
  """
  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  @doc """
  Gets document from AA
  """
  def get_document(id, type) do
    # AA requires 500 ms wait time between each request
    :timer.sleep(500)

    expected_content_type = NewsIngester.AAHelper.get_expected_content_type(type)

    url = NewsIngester.AAHelper.generate_url(:a_a_document_path, id, type)
    header = NewsIngester.AAHelper.generate_auth_header()

    {:ok, response} = HTTPoison.get(url, header)
    response_headers = Enum.into(response.headers, %{})
    content_type = response_headers["Content-Type"]

    cond do
      response.status_code == 429 ->
        # TODO need better handling here to avoid lockout
        # :timer.sleep(1_000 * NewsIngester.get_config(:a_a_429_wait_time))
        # get_document(id, type)
        nil

      String.contains?(content_type, expected_content_type) ->
        response

      true ->
        Logger.error("Could not get document: #{id}")
        Logger.error("#{response.body}/#{response.status_code}")
        nil
    end
  end
end
