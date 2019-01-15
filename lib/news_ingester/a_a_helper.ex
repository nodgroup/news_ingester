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
  def generate_search_filter do
    # lets start by setting a high limit, since we'll do time based filtering
    # it'll also make sure we don't miss anything when we restart the application after a long idle period
    ["limit", "100000"]
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

      _ ->
        Logger.error("Could not generate expected content type for: #{type}}")
        nil
    end
  end
end
