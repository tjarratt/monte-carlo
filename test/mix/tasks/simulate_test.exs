defmodule Mix.Tasks.SimulateTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Simulate

  describe "parse_stories_remaining/1" do
    test "accepts integers greater than zero" do
      assert {:ok, 12} = Simulate.parse_stories_remaining("12")
    end

    test "rejects zero, negatives, and non-integers" do
      assert {:error, _reason} = Simulate.parse_stories_remaining("0")
      assert {:error, _reason} = Simulate.parse_stories_remaining("-2")
      assert {:error, _reason} = Simulate.parse_stories_remaining("3.2")
      assert {:error, _reason} = Simulate.parse_stories_remaining("abc")
    end
  end

  describe "parse_release_date/2" do
    test "rejects non-ISO date values" do
      assert {:error, _reason} = Simulate.parse_release_date("2026/01/02", ~D[2026-01-01])
      assert {:error, _reason} = Simulate.parse_release_date("", ~D[2026-01-01])
    end

    test "rejects dates that are not in the future" do
      assert {:error, _reason} = Simulate.parse_release_date("2026-01-01", ~D[2026-01-01])
      assert {:error, _reason} = Simulate.parse_release_date("2025-12-31", ~D[2026-01-01])
    end

    test "accepts future Fridays without warning" do
      assert {:ok, ~D[2026-01-09], nil} =
               Simulate.parse_release_date("2026-01-09", ~D[2026-01-01])
    end

    test "rounds non-Friday dates to the nearest Friday and warns" do
      assert {:ok, ~D[2026-01-02], warning} =
               Simulate.parse_release_date("2026-01-05", ~D[2026-01-01])

      assert warning =~ "not a Friday"
      assert warning =~ "2026-01-02"
    end

    test "rejects input when nearest Friday is not in the future" do
      assert {:error, _reason} = Simulate.parse_release_date("2026-01-05", ~D[2026-01-04])
    end
  end
end
