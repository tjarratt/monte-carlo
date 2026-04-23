defmodule Mix.Tasks.Simulate.UserInputTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Simulate.UserInput

  describe "parse_stories_remaining/1" do
    test "accepts integers greater than zero" do
      assert {:ok, 12} = UserInput.parse_stories_remaining("12")
    end

    test "rejects zero, negatives, and non-integers" do
      assert {:error, _reason} = UserInput.parse_stories_remaining("0")
      assert {:error, _reason} = UserInput.parse_stories_remaining("-2")
      assert {:error, _reason} = UserInput.parse_stories_remaining("3.2")
      assert {:error, _reason} = UserInput.parse_stories_remaining("abc")
    end
  end

  describe "parse_release_date/2" do
    test "accepts future Fridays without warning" do
      assert {:ok, ~D[2026-01-09], nil} =
               UserInput.parse_release_date("2026-01-09", ~D[2026-01-01])
    end

    test "rejects non-ISO date values" do
      assert {:error, "release date must be in YYYY-mm-dd format"} =
               UserInput.parse_release_date("2026/01/02", ~D[2026-01-01])

      assert {:error, _reason} = UserInput.parse_release_date("garbage", ~D[2026-01-01])
      assert {:error, _reason} = UserInput.parse_release_date("", ~D[2026-01-01])
    end

    test "rejects dates that are not in the future" do
      assert {:error, "release date must be in the future"} =
               UserInput.parse_release_date("2026-01-01", ~D[2026-01-01])

      assert {:error, "release date must be in the future"} =
               UserInput.parse_release_date("2025-12-31", ~D[2026-01-01])
    end

    test "rounds release dates to the nearest Friday and warns" do
      {:ok, nearest_friday, warning} =
        UserInput.parse_release_date("2026-01-05", ~D[2026-01-01])

      assert nearest_friday == ~D[2026-01-02]

      assert warning == "Warning: 2026-01-05 is not a Friday; using nearest Friday 2026-01-02."
    end

    @friday ~D[2026-01-02]
    test "always rounds to the closest friday (at most 3 days before or after)" do
      assert_is_friday(UserInput.parse_release_date("2026-01-04", ~D[2025-01-01]))
      assert_is_friday(UserInput.parse_release_date("2026-01-03", ~D[2025-01-01]))
      assert_is_friday(UserInput.parse_release_date("2026-01-02", ~D[2025-01-01]))
      assert_is_friday(UserInput.parse_release_date("2026-01-01", ~D[2025-01-01]))
      assert_is_friday(UserInput.parse_release_date("2025-12-31", ~D[2025-01-01]))
      assert_is_friday(UserInput.parse_release_date("2025-12-30", ~D[2025-01-01]))
    end

    test "doesn't round to the same friday in the same week, if it would be 4+ days away" do
      {:ok, date, _warning} = UserInput.parse_release_date("2025-12-29", ~D[2025-01-01])
      assert date != @friday

      {:ok, date, _warning} = UserInput.parse_release_date("2025-12-29", ~D[2025-01-01])
      assert date != @friday
    end

    defp assert_is_friday({:ok, date, _warning}) do
      assert date == @friday
    end
  end
end
