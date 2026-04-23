defmodule Mix.Tasks.Simulate.InputCacheTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Simulate.InputCache

  @test_cache_file "tmp/test_simulate_inputs_#{:erlang.unique_integer([:positive])}.json"

  setup do
    Application.put_env(:montecarlo_simulation, :input_cache_file, @test_cache_file)
    File.rm(@test_cache_file)

    on_exit(fn ->
      File.rm(@test_cache_file)
      Application.delete_env(:montecarlo_simulation, :input_cache_file)
    end)

    :ok
  end

  describe "read/1 and write/2" do
    test "returns nil when no cache file exists" do
      assert InputCache.read(:board_id) == nil
    end

    test "write persists a value and read retrieves it" do
      InputCache.write(:board_id, "42")
      assert InputCache.read(:board_id) == "42"
    end

    test "write updates an existing key without losing other keys" do
      InputCache.write(:board_id, "10")
      InputCache.write(:stories_remaining, "25")
      InputCache.write(:board_id, "99")

      assert InputCache.read(:board_id) == "99"
      assert InputCache.read(:stories_remaining) == "25"
    end

    test "returns nil for a key that has never been written" do
      InputCache.write(:board_id, "1")
      assert InputCache.read(:stories_remaining) == nil
    end

    test "converts non-string keys to strings" do
      InputCache.write(:release_date, "2027-06-11")
      assert InputCache.read(:release_date) == "2027-06-11"
    end
  end
end
