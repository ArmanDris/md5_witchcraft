defmodule Md5Manager do
  use GenServer

  @alphabet Enum.map(?a..?z, &<<&1>>)
  @base length(@alphabet)
  # Chunk size is the range of indexes each worker will
  # be given
  @chunk_size 500_000
  @max_concurrent_workers 125

  @typedoc """
  State to track solved/unsolved hashes as well
  as alloted/unalloted/searched ranges of indexes
  """
  @type state :: %{
          unsolved_hashes: MapSet.t(binary()),
          solved_hashes: %{binary() => String.t()},
          available_indexes: Range.t() | :empty,
          allotted_ranges: MapSet.t(Range.t() | :empty),
          searched_ranges: MapSet.t(Range.t() | :empty)
        }

  @spec start_link({MapSet.t(binary()), pos_integer()}) :: GenServer.on_start()
  def start_link({hashes, password_size}) do
    GenServer.start_link(__MODULE__, {hashes, password_size}, name: __MODULE__)
  end

  @spec init({MapSet.t(binary()), pos_integer()}) :: {:ok, state, {:continue, term()}}
  def init({hashes, password_size}) do
    total_permutations = Integer.pow(@base, password_size)

    {
      :ok,
      %{
        unsolved_hashes: hashes,
        solved_hashes: %{},
        available_indexes: 0..total_permutations,
        allotted_ranges: MapSet.new(),
        searched_ranges: MapSet.new()
      },
      {
        :continue,
        {:spawn_workers, password_size}
      }
    }
  end

  def handle_continue({:spawn_workers, password_size}, state) do
    # This will calculate the total number of workers to
    # search the 
    ceil_div = fn a, b -> div(a + b - 1, b) end
    remaining_workers_needed = ceil_div.(state.available_indexes.last, @chunk_size)

    for _ <- 1..remaining_workers_needed do
      DynamicSupervisor.start_child(
        Md5WorkerSupervisor,
        %{
          id: Md5Worker,
          start: {Md5Worker, :start_link, [{Md5Manager, password_size}]},
          restart: :temporary,
          type: :worker
        }
      )
    end

    IO.puts("Spawned #{remaining_workers_needed} workers")

    {:noreply, state}
  end

  def handle_cast({:found, hash, word}, state) do
    IO.puts("Found match for #{Base.encode16(hash, case: :lower)}: #{word}")

    new_state = %{
      state
      | unsolved_hashes: MapSet.delete(state.unsolved_hashes, hash),
        solved_hashes: Map.put(state.solved_hashes, hash, word)
    }

    {:noreply, new_state}
  end

  @spec handle_cast({:finished, Range.t()}, state) :: {:noreply, state}
  def handle_cast({:finished, range}, state) do
    new_state = %{
      state
      | allotted_ranges: MapSet.delete(state.allotted_ranges, range),
        searched_ranges: MapSet.put(state.searched_ranges, range)
    }

    {:noreply, new_state}
  end

  @spec handle_call(:get_new_range, GenServer.from(), state) :: {:reply, Range.t(), state}
  def handle_call(:get_new_range, _from, state) do
    {next_ten_thousand_index, new_available_range} =
      case state.available_indexes do
        %Range{} = r -> pop_first_x_indexes(r, @chunk_size)
        :empty -> {:empty, :empty}
      end

    new_state = %{
      state
      | available_indexes: new_available_range,
        allotted_ranges: MapSet.put(state.allotted_ranges, next_ten_thousand_index)
    }

    {:reply, {next_ten_thousand_index, new_state.unsolved_hashes}, new_state}
  end

  @spec pop_first_x_indexes(Range.t(), pos_integer()) :: {Range.t() | :empty, Range.t() | :empty}
  def pop_first_x_indexes(%Range{first: start, last: stop}, size)
      when start < stop do
    cond do
      start + size >= stop -> {start..stop, :empty}
      true -> {start..(start + size), (start + size)..stop}
    end
  end
end
