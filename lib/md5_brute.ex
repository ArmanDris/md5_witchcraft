defmodule Md5Brute do
  @moduledoc """
  A set of functions for breaking an md5 hash
  """

  @doc """
  This function will take the first command line arg as the string
  to hash and brute force. It will output its results to the terminal
  """
  def run_from_cmd do
    word = parse_args()
    word_length = String.length(word)
    binary_md5_hashed_word = :crypto.hash(:md5, word)
    IO.puts(
      "Breaking hash #{binary_md5_hashed_word |> Base.encode16(case: :lower)} " <>
      " with a words of length #{word_length}"
    )
    run_breaker(binary_md5_hashed_word, word_length)
      |> IO.inspect()
  end

  @doc """
  run_breaker
  """
  @spec run_breaker(binary(), integer()) :: {:ok, String.t()} | :error
  def run_breaker(hash, length) do
    letters = Enum.map(?a..?z, &<<&1>>)
    combinations = gen_permutations(letters, length)
    find_letter(hash, combinations)
  end

  # Returns the first command line arg,
  # returns abc if none were provided
  @spec parse_args() :: String.t()
  defp parse_args do
    args = System.argv()
    case args do
      [first | _] -> first
      _ -> "abc"
    end
  end

  @spec find_letter(binary(), [String.t()]) :: {:ok, String.t()} | :error
  defp find_letter(_, []), do: :error
  defp find_letter(hash, [s | rest]) do
    hashed_letter = :crypto.hash(:md5, s)
    if hashed_letter == hash do
      {:ok, s}
    else
      find_letter(hash, rest)
    end
  end

  @spec gen_permutations(list(String.t()), integer()) :: list(String.t())
  defp gen_permutations(_, 0) do
    [""]
  end
  defp gen_permutations(list, n) do
    for elem <- list,
      rest <- gen_permutations(list, n - 1),
      do: elem <> rest
  end
    
end
