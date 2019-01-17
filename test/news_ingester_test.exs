defmodule NewsIngesterTest do
  use ExUnit.Case
  doctest NewsIngester

  test "get test value from config" do
    assert NewsIngester.get_config(:key) == "value"
  end

  test "should get table list from dynamodb" do
    assert is_map(
             ExAws.Dynamo.list_tables()
             |> ExAws.request!()
           )
  end
end
