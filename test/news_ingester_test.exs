defmodule NewsIngesterTest do
  use ExUnit.Case
  doctest NewsIngester

  test "get test value from config" do
    assert NewsIngester.get_config(:key) == "value"
  end
end
