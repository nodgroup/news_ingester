defmodule NewsIngester.AACrawler do
  use GenServer
  require Logger
  import SweetXml
  @moduledoc false

  ## Client API

  @doc """
  Crawler logic
  """
  def crawl do
    server = NewsIngester.AACrawler
    results = search(server, false)

    results
    |> Enum.each(fn result -> process_results(server, result) end)

    :timer.sleep(1_000 * NewsIngester.get_config(:a_a_crawl_timer))
    crawl()
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
  def search(server, is_test) do
    GenServer.call(server, {:search, is_test})
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

  def handle_call({:search, is_test}, _from, state) do
    # AA requires 500 ms wait time between each request
    :timer.sleep(500)

    url = NewsIngester.AAHelper.generate_url(:a_a_search_path)
    header = NewsIngester.AAHelper.generate_auth_header()
    filter = NewsIngester.AAHelper.generate_search_filter(is_test)
    {:ok, response} = HTTPoison.post(url, filter, header)

    body =
      response.body
      |> Poison.Parser.parse!(%{})

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
    title = elem(element, 0)
    ids = elem(element, 1)

    results =
      ids
      |> Enum.reduce(
        %{},
        fn e, acc ->
          props = String.split(e, ":")
          type = Enum.at(props, 1)

          case type do
            "picture" ->
              NewsIngester.AAHelper.get_document_body(e, type)
              acc

            "video" ->
              NewsIngester.AAHelper.get_document_body(e, type)
              acc

            "text" ->
              result = NewsIngester.AAHelper.get_document_body(e, type)

              try do
                Map.merge(
                  acc,
                  %{
                    "summary" =>
                      result
                      |> xpath(~x"//abstract/text()"S),
                    "content" =>
                      result
                      |> xpath(~x"//body.content/text()"S),
                    "author" =>
                      result
                      |> xpath(~x"//creator[@qcode=\"AArole:author\"]/@literal"S),
                    "publisher" =>
                      result
                      |> xpath(~x"//creator[@qcode=\"AArole:publisher\"]/@literal"S),
                    "categories" =>
                      result
                      |> xpath(~x"//subject/name[@xml:lang=\"tr\"]/text()"Sl),
                    "keywords" =>
                      result
                      |> xpath(~x"//keyword/text()"Sl),
                    "city" =>
                      result
                      |> xpath(~x"//located/name[@xml:lang=\"tr\"]/text()"S),
                    "country" =>
                      result
                      |> xpath(~x"//broader/name[@xml:lang=\"tr\"]/text()"S),
                    "content_created_at" =>
                      result
                      |> xpath(~x"//contentCreated/text()"S)
                  }
                )
              catch
                :exit, _ ->
                  Logger.error("Unable to parse text for: #{e}")
                  acc
              end

            _ ->
              Logger.error("Type not recognized: #{type}")
              acc
          end
        end
      )

    results
    |> Map.merge(%{"title" => title, "ids_at_source" => ids})
    |> post_text

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
        Logger.error("Returned status code 429 for: #{id}")
        nil

      String.contains?(content_type, expected_content_type) ->
        response

      true ->
        Logger.error("Could not get document: #{id}")
        Logger.error("#{response.body}/#{response.status_code}")
        nil
    end
  end

  @doc """
  Sends results with graphql
  """
  def post_text(entity) do
    {status, response} =
      Neuron.query(
        """
        mutation insert_ingested_articles_aa($objects: [ingested_articles_aa_insert_input!]!) {
          insert_ingested_articles_aa(objects: $objects) {
            returning {
              id
            }
          }
        }
        """,
        %{"objects" => [entity]}
      )

    if status == :error do
      Logger.error("Could not post to graphql: #{entity["ids_at_source"]}")
      IO.inspect(response)
    end
  end
end
