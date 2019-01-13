defmodule NewsIngester.AACrawlerTest do
  use ExUnit.Case

  setup do
    server = start_supervised!(NewsIngester.AACrawler)
    %{server: server}
  end

  test "should get search results", %{server: server} do
    result = NewsIngester.AACrawler.search(server)
    assert is_map(result)
  end
end
