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
end
