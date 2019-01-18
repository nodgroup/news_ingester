defmodule NewsIngester.AACrawlerTest do
  use ExUnit.Case

  setup do
    server = start_supervised!(NewsIngester.AACrawler)
    %{server: server}
  end

  test "should get search results", %{server: server} do
    result = NewsIngester.AACrawler.search(server, true)
    assert is_map(result)
  end

  test "should get picture", %{server: server} do
    result = NewsIngester.AACrawler.search(server, true)

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

  test "should get text", %{server: server} do
    result = NewsIngester.AACrawler.search(server, true)

    id =
      result
      |> Enum.find_value(fn {_k, v} ->
        v |> Enum.find(fn v -> String.contains?(v, "text") end)
      end)

    result = NewsIngester.AACrawler.get_document(id, "text")
    headers = Enum.into(result.headers, %{})
    content_type = headers["Content-Type"]
    assert content_type == "application/xml"
  end
end
