defmodule NewsIngesterTest do
  use ExUnit.Case
  doctest NewsIngester

  test "get test value from config" do
    assert NewsIngester.get_config(:key) == "value"
  end

  test "should generate http basic auth header" do
    result = NewsIngester.generate_auth_header()
    assert is_tuple(result) == true
  end
end
