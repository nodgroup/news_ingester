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
    Task.Supervisor.start_child(Task.Supervisor, fn -> NewsIngester.AACrawler.crawl() end)
    app
  end
end
