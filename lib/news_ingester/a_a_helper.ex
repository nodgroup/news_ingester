defmodule NewsIngester.AAHelper do
  require Logger
  import SweetXml
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

      "picturegroup" ->
        NewsIngester.get_config(:a_a_text_type)

      "videogroup" ->
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

      "picturegroup" ->
        "xml"

      "videogroup" ->
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

  @doc """
  Generated metadata from xml for videos and pictures
  """
  def generate_metadata(result, id, type) do
    base_xpath = "//newsItem[@guid=\"#{id}\"]"
    content_meta_path = "#{base_xpath}/contentMeta"

    metadata = %{
      "headline" => result |> xpath(~x"#{content_meta_path}/headline/text()"S),
      "description" => result |> xpath(~x"#{content_meta_path}/description/text()"S),
      "categories" =>
        result |> xpath(~x"#{content_meta_path}/subject/name[@xml:lang=\"tr\"]/text()"Sl),
      "publisher" =>
        result |> xpath(~x"#{content_meta_path}/creator[@qcode=\"AArole:publisher\"]/@literal"S),
      "city" => result |> xpath(~x"#{content_meta_path}/located/name[@xml:lang=\"tr\"]/text()"S),
      "country" =>
        result |> xpath(~x"#{content_meta_path}/located/broader/name[@xml:lang=\"tr\"]/text()"S),
      "content_created_at" => result |> xpath(~x"#{content_meta_path}/contentCreated/text()"S),
      "keywords" => result |> xpath(~x"#{content_meta_path}/keyword/text()"Sl),
      "copyright_holder" =>
        result |> xpath(~x"#{base_xpath}/rightsInfo/copyrightHolder/@literal"S)
    }

    case type do
      "video" ->
        Map.merge(metadata, %{
          "cameraman" =>
            result
            |> xpath(~x"#{content_meta_path}/creator[@qcode=\"AArole:cameraman\"]/@literal"S)
        })

      "picture" ->
        Map.merge(metadata, %{
          "photographer" =>
            result
            |> xpath(~x"#{content_meta_path}/creator[@qcode=\"AArole:photographer\"]/@literal"S)
        })

      _ ->
        metadata
    end
  end

  @doc """
  Gets results and generates data for text news
  """
  def generate_text_data(e, type, acc) do
    if type == "text" do
      result = get_document_body(e, type)

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
    else
      Logger.error("Type not recognized: #{type}")
      acc
    end
  end
end
