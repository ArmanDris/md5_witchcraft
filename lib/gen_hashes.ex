defmodule GenHashes do
  @moduledoc"""
  Functions for generating lists
  of hashed passwords. When the
  module is run the first command
  line arg is taken as the number
  of password to generate and the
  second command line arg is
  the length of each password
  before it is encrypted
  """

  def gen_hashes do
    case System.argv() do
      [first_str, second_str| _ ] ->
          case {Integer.parse(first_str), Integer.parse(second_str)} do
            {{first, ""}, {second, ""}} ->
              gen_hashes(first, second)
            _ ->
              IO.puts("Usage: mix run -e GenHashes.gen_hashes <num_hashes> <passwd_len>")
          end
      _ ->
        IO.puts("Usage: mix run -e GenHashes.gen_hashes <num_hashes> <passwd_len>")
    end
  end

  @spec gen_hashes(integer(), integer()):: :ok
  def gen_hashes(0, _) do :ok end
  def gen_hashes(num_hashes, hash_len) do
    str = for _ <- 1..hash_len, into: "", do: <<Enum.random(?a..?z)>>
    md5_hashed_word = :crypto.hash(:md5, str)
      |> Base.encode16(case: :lower)
    IO.puts(md5_hashed_word)
    gen_hashes(num_hashes - 1, hash_len)
  end
    
end
