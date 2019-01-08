defmodule NewsIngester do
  @moduledoc false

  @doc """
  Gets value from config using key
  """
  def get_config(key) do
    Application.get_env(:news_ingester, key)
  end

  @doc """
  Generates http basic authentication header from config
  """
  def generate_auth_header do
    username = get_config(:api_username)
    password = get_config(:api_password)
    {'Authorization', 'Basic ' ++ :base64.encode_to_string('#{username}:#{password}}')}
  end
end
