defmodule NewsIngester.AAHelperTest do
  use ExUnit.Case

  test "should generate http basic auth header" do
    result = NewsIngester.AAHelper.generate_auth_header()
    assert is_list(result) == true
  end

  test "should generate filter" do
    result = NewsIngester.AAHelper.generate_search_filter()
    assert is_list(result) == true
  end
end
