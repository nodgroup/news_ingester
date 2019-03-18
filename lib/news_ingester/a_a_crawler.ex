defmodule NewsIngester.AACrawler do
  use GenServer
  require Logger
  @moduledoc false

  ## Client API

  @doc """
  Crawler logic
  """
  def crawl(dir_path, gcs_conn) do
    server = NewsIngester.AACrawler
    results = search(server, false)

    results
    |> Enum.each(fn result -> process_results(server, result, dir_path, gcs_conn) end)

    :timer.sleep(1_000 * NewsIngester.get_config(:a_a_crawl_timer))
    crawl(dir_path, gcs_conn)
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
  def process_results(server, element, dir_path, gcs_conn) do
    GenServer.cast(server, {:process_results, element, dir_path, gcs_conn})
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
            id = NewsIngester.AAHelper.get_id(result)
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

  def handle_cast({:process_results, element, dir_path, gcs_conn}, state) do
    title = elem(element, 0)
    ids = elem(element, 1)

    results =
      ids
      |> Enum.reduce(
        %{},
        fn e, acc ->
          case is_list(e) do
            true ->
              [group, id] = e
              group_props = String.split(group, ":")
              group_type = Enum.at(group_props, 1)
              props = String.split(id, ":")
              type = Enum.at(props, 1)

              result = NewsIngester.AAHelper.get_document_body(group, group_type)

              metadata = NewsIngester.AAHelper.generate_metadata(result, id, type)

              asset = get_document(id, type)

              if asset != nil do
                IO.inspect("doing video")
                public_url = send_to_gcs(asset, metadata, dir_path, gcs_conn)

                {:ok, manipulator_response} =
                  HTTPoison.post(
                    NewsIngester.get_config(:asset_manipulator_endpoint),
                    Poison.encode!(%{
                      "type" => NewsIngester.AAHelper.get_type_for_asset_manipulator(type),
                      "metadata" => metadata,
                      "url" => public_url
                    }),
                    "Content-Type": "application/json"
                  )

                attachments = Map.get(acc, "attachments")

                if attachments == nil do
                  Map.merge(acc, %{"attachments" => [manipulator_response.body]})
                else
                  Map.merge(acc, %{"attachments" => attachments ++ [manipulator_response.body]})
                end
              else
                acc
              end

            false ->
              props = String.split(e, ":")
              type = Enum.at(props, 1)

              NewsIngester.AAHelper.generate_text_data(e, type, acc)
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
    {status, _response} =
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
    end
  end

  @doc """
  Sends files to cloud storage
  """
  def send_to_gcs(asset, metadata, dir_path, gcs_conn) do
    if asset != nil do
      fileName =
        asset.headers
        |> Enum.filter(fn {k, _} -> k == "Content-Disposition" end)
        |> hd
        |> elem(1)
        |> String.split("=")
        |> Enum.at(1)

      File.write(Path.join(dir_path, fileName), asset.body)

      # save to google cloud storage with public permissions
      {:ok, object} =
        GoogleApi.Storage.V1.Api.Objects.storage_objects_insert_simple(
          gcs_conn,
          NewsIngester.get_config(:gcs_storage),
          "multipart",
          NewsIngester.AAHelper.merge_metadata(fileName, metadata),
          Path.join(dir_path, fileName),
          predefinedAcl: "publicRead"
        )

      File.rm(Path.join(dir_path, fileName))

      object.mediaLink
    end
  end
end
