defmodule NewsIngester.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: NewsIngester.Worker.start_link(arg)
      # {NewsIngester.Worker, arg},
      {NewsIngester.AACrawler, name: NewsIngester.AACrawler},
      {Task.Supervisor, name: Task.Supervisor, restart: :transient}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NewsIngester.Supervisor]
    app = Supervisor.start_link(children, opts)
    NewsIngester.create_table("a_a_crawler", :key, :string)
    Neuron.Config.set(url: NewsIngester.get_config(:graphql_url))

    Neuron.Config.set(
      headers: [
        "x-hasura-admin-secret": NewsIngester.get_config(:graphql_token)
      ]
    )

    # generated tmp dir for assets
    {:ok, dir_path} = Temp.mkdir()

    Task.Supervisor.start_child(Task.Supervisor, fn ->
      NewsIngester.AACrawler.crawl(dir_path)
    end)

    app
  end
end
