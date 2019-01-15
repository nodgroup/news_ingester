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

  test "should get picture", %{server: server} do
    result = NewsIngester.AACrawler.search(server)

    id =
      result
      |> Enum.find_value(fn {_k, v} ->
        v |> Enum.find(fn v -> String.contains?(v, "picture") end)
      end)

    result = NewsIngester.AACrawler.get_document(id, "picture")
    headers = Enum.into(result.headers, %{})
    content_type = headers["Content-Type"]
    assert content_type == "image/jpeg"
  end
end
