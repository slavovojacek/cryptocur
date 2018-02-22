defmodule Cryptocur.Supervisor do
  use Supervisor

  def start_link do
    IO.puts("Starting the Supervisor ...")
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      Cryptocur.Blockchain
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
