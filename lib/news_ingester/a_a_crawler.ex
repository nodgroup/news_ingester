defmodule NewsIngester.AACrawler do
  use GenServer
  @moduledoc false

  ## Client API

  @doc """
  Starts GenServer
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  ## Server Callbacks

  @doc """
  Initializes GenServer
  """
  def init(_opts) do
    {:ok, %{}}
  end

  @doc """
  Default fallback for calls
  """
  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  @doc """
  Default fallback for casts
  """
  def handle_cast(_msg, state) do
    {:noreply, state}
  end
end
