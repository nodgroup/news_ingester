defmodule NewsIngester do
  @moduledoc false

  @doc """
  Gets value from config using key
  """
  def get_config(key) do
    Application.get_env(:news_ingester, key)
  end
end
