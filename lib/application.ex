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

      {:ok, pid} = Supervisor.start_link(children, opts)

      # Montior MD5 Manager to shut it down when it exits
      spawn(fn ->
        Process.flag(:trap_exit, true)
        md5_manager = Process.whereis(Md5Manager)
        ref = Process.monitor(md5_manager)

        receive do
          {:DOWN, ^ref, :process, ^md5_manager, :normal} ->
            IO.puts("Md5Manager completed successfully. Exiting app.")
            System.halt(0)

          {:DOWN, ^ref, :process, ^md5_manager, reason} ->
            IO.puts("Md5Manager crashed with reason: #{inspect(reason)}")
            System.halt(1)
        end
      end)

      {:ok, pid}
    end
  end
end
