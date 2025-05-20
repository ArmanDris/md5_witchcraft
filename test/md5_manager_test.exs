defmodule Md5ManagerTest do
  use ExUnit.Case
  doctest Md5Manager

  @passwd "aaa"
  @passwd_len String.length(@passwd)
  @sample_hash :crypto.hash(:md5, @passwd)

  test "verify 'pops' range indexes like expected" do
    # Providing two empty indexes should result in
    # two empty indexes being returned
    assert Md5Manager.pop_first_x_indexes(5..10, 3) == {5..8, 8..10}
    assert Md5Manager.pop_first_x_indexes(0..10, 5) == {0..5, 5..10}
    assert Md5Manager.pop_first_x_indexes(0..9, 10) == {0..9, :empty}
  end

  test "make sure GenServer working as expected" do
    {:ok, pid} = Md5Manager.start_link({MapSet.new([@sample_hash]), @passwd_len})
    state_after_init = :sys.get_state(pid)

    assert state_after_init.solved_hashes == %{}
    assert MapSet.member?(state_after_init.unsolved_hashes, @sample_hash)
    assert state_after_init.available_indexes == 0..Integer.pow(26, @passwd_len)

    {range_one, unsolved_hashes_one} = GenServer.call(pid, :get_new_range)
    {range_two, unsolved_hashes_two} = GenServer.call(pid, :get_new_range)
    {range_three, unsolved_hashes_three} = GenServer.call(pid, :get_new_range)
    assert range_one == 0..10000
    assert range_two == 10000..17576
    assert range_three == :empty

    assert unsolved_hashes_one == unsolved_hashes_two
    assert unsolved_hashes_two == unsolved_hashes_three
    assert unsolved_hashes_three == MapSet.new([@sample_hash])

    state_after_all_allotted = :sys.get_state(pid)
    assert state_after_all_allotted.available_indexes == :empty
    assert MapSet.size(state_after_all_allotted.allotted_ranges) == 3
    assert state_after_all_allotted.searched_ranges == MapSet.new()

    GenServer.cast(pid, {:finished, range_two})
    state_afet_finished = :sys.get_state(pid)
    assert state_afet_finished.available_indexes == :empty
    assert MapSet.size(state_afet_finished.allotted_ranges) == 2
    assert state_afet_finished.searched_ranges == MapSet.new([range_two])

    GenServer.cast(pid, {:found, @sample_hash, @passwd})
    state_after_found = :sys.get_state(pid)
    assert state_after_found.solved_hashes == %{@sample_hash => @passwd}
    assert state_after_found.unsolved_hashes == MapSet.new()
  end
end
