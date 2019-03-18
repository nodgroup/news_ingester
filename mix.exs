defmodule NewsIngester.MixProject do
  use Mix.Project

  def project do
    [
      app: :news_ingester,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {NewsIngester.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},

      # code analysis tool
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      # dynamodb connector
      {:ex_aws_dynamo, "~> 2.0"},
      # graphql client
      {:neuron, "~> 1.1.0"},
      # :xmerl wrapper for parsing xml
      {:sweet_xml, "~> 0.6.5"},
      # for logging to file
      {:logger_file_backend, "~> 0.0.10"},
      # generates tmp dir for cloud storage
      {:temp, "~> 0.4.7"},
      # auth library
      {:goth, "~> 1.0"},
      # cloud storage api
      {:google_api_storage, "~> 0.1.0"}
    ]
  end

  defp aliases do
    [
      test: "test --no-start"
    ]
  end
end
