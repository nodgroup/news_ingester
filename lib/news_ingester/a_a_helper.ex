defmodule NewsIngester.AAHelper do
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
      "Could not generate url"
    end
  end

  @doc """
  Generates url with quality parameter
  """
  def generate_url(key, id, quality) do
    base = generate_url(key)
    quality = "/" <> id <> "/" <> NewsIngester.get_config(quality)

    if is_bitstring(base) && is_bitstring(quality) do
      base <> quality
    else
      "Could not generate url"
    end
  end

  @doc """
  Gets picture from AA
  """
  def get_picture(id) do
    url = NewsIngester.AAHelper.generate_url(:a_a_picture_path, id, :a_a_picture_quality)
    header = NewsIngester.AAHelper.generate_auth_header()

    {:ok, response} = HTTPoison.get(url, header)
  end
end
