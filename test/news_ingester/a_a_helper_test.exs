defmodule NewsIngester.AAHelperTest do
  use ExUnit.Case

  test "should generate http basic auth header" do
    result = NewsIngester.AAHelper.generate_auth_header()
    assert is_list(result) == true
  end
end
