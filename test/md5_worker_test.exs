defmodule Md5WorkerTest do
  use ExUnit.Case

  # @passwd "aaa"
  # @passwd_len String.length(@passwd)
  # @sample_hash :crypto.hash(:md5, @passwd)

  doctest Md5Worker

  test "verify can go from index range " <>
         " and length to pemutations" do
    # a b c d e f g h i j 
    # 0 1 2 3 4 5 6 7 8 9 
    assert GenPermutations.gen_permutations(2, 6, 1) == {:ok, ["c", "d", "e", "f"]}
    assert GenPermutations.gen_permutations(0, 3, 2) == {:ok, ["aa", "ab", "ac"]}
    assert GenPermutations.gen_permutations(0, 4, 4) == {:ok, ["aaaa", "aaab", "aaac", "aaad"]}
    # 26^4 = 456976. So there are 456976 permutations rangin from
    # 0 - 456975. Then intuatuvely the last few should be
    # ["zzzx", "zzzy", "zzzz"]
    # Note we still write the stop index as 456976 because the stop
    # index is not inclusive
    assert GenPermutations.gen_permutations(456_972, 456_976, 4) ==
             {:ok, ["zzzw", "zzzx", "zzzy", "zzzz"]}

    assert {:error, _reason} = GenPermutations.gen_permutations(25, 27, 1)
    assert {:error, _reason} = GenPermutations.gen_permutations(456_975, 456_977, 4)
    assert {:error, _reason} = GenPermutations.gen_permutations(-1, 20, 2)
    assert {:error, _reason} = GenPermutations.gen_permutations(2, -2, 2)
  end
end
