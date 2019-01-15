defmodule NewsIngester do
  @moduledoc false

  @doc """
  Gets value from config using key
  """
  def get_config(key) do
    Application.get_env(:news_ingester, key)
  end

  @doc """
  Creates DynamoDB table and raises error on unhandled exception
  """
  def create_table(table_name, primary_key, pk_type) do
    tables = ExAws.Dynamo.list_tables() |> ExAws.request!()

    if Enum.member?(tables["TableNames"], table_name) == false do
      ExAws.Dynamo.create_table(table_name, primary_key, %{"#{primary_key}": pk_type}, 1, 1)
      |> ExAws.request!()
    end
  end
end
