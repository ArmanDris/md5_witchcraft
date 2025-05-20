defmodule Md5BruteTest do
  use ExUnit.Case
  doctest Md5Brute

  test "run_breaker correct return type" do
    assert Md5Brute.run_breaker(:crypto.hash(:md5, "zyz"), 3) == {:ok, "zyz"}
    assert Md5Brute.run_breaker(:crypto.hash(:md5, "zyza"), 3) == :error
  end
end
