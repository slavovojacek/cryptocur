defmodule Cryptocur do
  use Application

  def start(_type, _args) do
    IO.puts("Starting the Application ...")
    Cryptocur.Supervisor.start_link()
  end
end
