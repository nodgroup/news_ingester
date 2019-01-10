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

  test "should generate url" do
    result = NewsIngester.AAHelper.generate_url(:a_a_search_path)
    assert is_bitstring(result) == true
  end

  test "should not generate url" do
    result = NewsIngester.AAHelper.generate_url(:invalid_key)
    assert result == "Could not generate url"
  end
end
