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
      |> URI.to_string()
    else
      "Could not generate url"
    end
  end
end
