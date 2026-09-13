defmodule Mix.Tasks.Simulate.InputCacheTest do
  use ExUnit.Case, async: false
  use Expect

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
      cached_result = InputCache.read(:board_id)

      expect(cached_result, to: be_nil())
    end

    test "write persists a value and read retrieves it" do
      InputCache.write(:board_id, "42")
      cached_result = InputCache.read(:board_id)

      expect(cached_result, to: equal("42"))
    end

    test "write updates an existing key without losing other keys" do
      InputCache.write(:board_id, "10")
      InputCache.write(:stories_remaining, "25")
      InputCache.write(:board_id, "99")

      board_id = InputCache.read(:board_id)
      expect(board_id, to: equal("99"))

      stories_remaining = InputCache.read(:stories_remaining)
      expect(stories_remaining, to: equal("25"))
    end
  end
end
