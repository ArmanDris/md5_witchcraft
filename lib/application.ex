defmodule Md5App.Application do
  use Application

  @password_len 6

  def start(_type, _args) do
    IO.inspect(Mix.env())

    if Mix.env() == :test do
      {:ok, self()}
    else
      hashes =
        MapSet.new([
          :crypto.hash(:md5, "zzzzzz"),
          :crypto.hash(:md5, "aaaaaa"),
          :crypto.hash(:md5, "llllll")
        ])

      children = [
        {DynamicSupervisor, strategy: :one_for_one, name: Md5WorkerSupervisor},
        {Md5Manager, {hashes, @password_len}}
      ]

      opts = [strategy: :one_for_one, name: Md5App.Supervisor]

      Supervisor.start_link(children, opts)
    end
  end
end
