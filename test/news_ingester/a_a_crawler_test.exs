defmodule NewsIngester.AACrawlerTest do
  use ExUnit.Case

  test "should get search results" do
    server = start_supervised!(NewsIngester.AACrawler)
    result = NewsIngester.AACrawler.search(server)
    assert is_tuple(result)
  end
end
