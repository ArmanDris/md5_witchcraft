defmodule Md5Worker do
  use GenServer

  @typedoc """
  State of Md5Worker
  """
  @type state :: %{
          manager: pid(),
          passwd_len: pos_integer()
        }

  def start_link({manager_pid, passwd_len}) do
    GenServer.start_link(__MODULE__, {manager_pid, passwd_len})
  end

  def init({manager_pid, passwd_len}) do
    {:ok, %{manager: manager_pid, passwd_len: passwd_len}, {:continue, :call_for_range}}
  end

  def handle_continue(:call_for_range, state) do
    {range, unsolved_hashes} = GenServer.call(state.manager, :get_new_range)

    case range do
      :empty ->
        IO.puts("received empty range. exiting")
        {:stop, :no_more_work, state}

      _ ->
        send(self(), {:search_range, {range, unsolved_hashes}})

        {:noreply, state}
    end
  end

  @doc """
  Will search through the range, reporting to the manager when
  any hashes are found or when the range is finished.
  """
  @spec handle_info({:search_range, {Range.t(), MapSet.t()}}, state) :: nil
  def handle_info({:search_range, {range, unsolved_hashes}}, state) do
    {:ok, permutations} =
      GenPermutations.gen_permutations(
        range.first,
        range.last,
        state.passwd_len
      )

    search_range(permutations, range, unsolved_hashes, state)
    {:stop, :normal, state}
  end

  @spec search_range([String.t()], Range.t(), MapSet.t(), state) :: nil
  defp search_range([], range, _, state) do
    GenServer.cast(state.manager, {:finished, range})
  end

  defp search_range([w | rest_of_words], range, unsolved_hashes, state) do
    hashed_w = :crypto.hash(:md5, w)

    if MapSet.member?(unsolved_hashes, hashed_w) do
      GenServer.cast(state.manager, {:found, hashed_w, w})
    end

    # We could remove the hash we just found from unsolved_hashes
    # but I dont want to.
    search_range(rest_of_words, range, unsolved_hashes, state)
  end
end

defmodule GenPermutations do
  @alphabet Enum.map(?a..?z, &<<&1>>)
  @base length(@alphabet)

  @doc """
  Generate the permutations for lowercase alphabet of
  length 4 in the range [start, stop)
  !!! NOTE THAT STOP IS NOT INCLUSIVE
  """
  @spec gen_permutations(integer(), integer(), integer()) ::
          {:ok, [String.t()]} | {:error, String.t()}
  def gen_permutations(start, stop, len) do
    max_index = Integer.pow(@base, len)

    cond do
      len < 1 ->
        {:error, "Length must be at least 1"}

      start < 0 or stop < 0 ->
        {:error, "Start and stop must be non-negative"}

      start > max_index or stop > max_index ->
        {:error, "Start or stop greater than the last permutation"}

      true ->
        permutations =
          start..(stop - 1)
          |> Enum.map(&index_to_word(&1, len))

        {:ok, permutations}
    end
  end

  defp index_to_word(index, length) do
    do_index_to_word(index, length, [])
  end

  defp do_index_to_word(_, 0, acc) do
    Enum.join(acc)
  end

  defp do_index_to_word(index, remaining, acc) do
    letter_index = rem(index, @base)
    letter = Enum.at(@alphabet, letter_index)
    do_index_to_word(div(index, @base), remaining - 1, [letter | acc])
  end
end
