defmodule NewsIngester.AAHelper do
  require Logger
  @moduledoc false

  @doc """
  Generates http basic authentication header from config
  """
  def generate_auth_header do
    username = NewsIngester.get_config(:api_username)
    password = NewsIngester.get_config(:api_password)

    if is_bitstring(username) && is_bitstring(password) do
      [Authorization: "Basic " <> Base.encode64("#{username}:#{password}")]
    else
      "Could not generate auth header"
    end
  end

  @doc """
  Generates search filter from config
  """
  def generate_search_filter(is_test) do
    if is_test do
      {:multipart, [{"limit", "100000"}]}
    else
      # lets start by setting a high limit, since we'll do time based filtering
      # it'll also make sure we don't miss anything when we restart the application after a long idle period
      filter = [{"limit", "100000"}, {"start_date", get_last_crawled()}]

      ExAws.Dynamo.put_item(
        "a_a_crawler",
        %{
          key: "last_crawled",
          value: DateTime.to_iso8601(DateTime.truncate(DateTime.utc_now(), :second))
        }
      )
      |> ExAws.request()

      {:multipart, filter}
    end
  end

  @doc """
  Gets last crawled for start date filter from dynamodb
  """
  def get_last_crawled do
    last_crawled =
      ExAws.Dynamo.get_item("a_a_crawler", %{key: "last_crawled"})
      |> ExAws.request!()

    if map_size(last_crawled) == 0 do
      "*"
    else
      last_crawled["Item"]["value"]["S"]
    end
  end

  @doc """
  Generates url from config and parameters
  """
  def generate_url(key) do
    base = NewsIngester.get_config(:a_a_base_url)
    path = NewsIngester.get_config(key)

    if is_bitstring(base) && is_bitstring(path) do
      base
      |> URI.merge(path)
      |> to_string()
    else
      Logger.error("Could not generate url for: #{key}")
      nil
    end
  end

  @doc """
  Generates document url from config
  """
  def generate_url(key, id, type) do
    base = generate_url(key)
    path = "/#{id}/#{get_quality(type)}"

    if is_bitstring(base) do
      "#{base}#{path}"
    else
      Logger.error("Could not generate url for: #{key}/#{id}/#{type}")
      nil
    end
  end

  @doc """
  Gets quality from config for appropriate content type
  """
  def get_quality(type) do
    case type do
      "picture" ->
        NewsIngester.get_config(:a_a_picture_quality)

      "video" ->
        NewsIngester.get_config(:a_a_video_quality)

      "text" ->
        NewsIngester.get_config(:a_a_text_type)

      _ ->
        Logger.error("Could not get quality for: #{type}")
        nil
    end
  end

  @doc """
  Get expected content type
  """
  def get_expected_content_type(type) do
    case type do
      "picture" ->
        "image"

      "video" ->
        "video"

      "text" ->
        "xml"

      _ ->
        Logger.error("Could not generate expected content type for: #{type}}")
        nil
    end
  end

  @doc """
  Returns document body or nil
  """
  def get_document_body(id, type) do
    document = NewsIngester.AACrawler.get_document(id, type)

    if document == nil do
      ""
    else
      document.body
    end
  end

  @doc """

  """
  def get_id(result) do
    id = result["id"]
    props = String.split(id, ":")
    type = Enum.at(props, 1)

    if type == "picture" || type == "video" do
      [[result["group_id"], id]]
    else
      [id]
    end
  end
end
