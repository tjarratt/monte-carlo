defmodule Mix.Tasks.Simulate.UserInputTest do
  # @related [subject](lib/mix/tasks/simulate/user_input.ex)
  use ExUnit.Case, async: true
  use Expect

  alias Mix.Tasks.Simulate.UserInput

  describe "parse_board_id/1" do
    test "accepts numeric board ids" do
      {:ok, parsed} = UserInput.parse_board_id("123")

      expect(parsed, to: equal("123"))
    end

    test "trims whitespace before validating" do
      {:ok, parsed} = UserInput.parse_board_id("  42  ")

      expect(parsed, to: equal("42"))
    end

    test "rejects empty input" do
      result = UserInput.parse_board_id("")
      expect(result, to: equal({:error, "jira board id cannot be empty"}))

      result = UserInput.parse_board_id("   ")
      expect(result, to: equal({:error, "jira board id cannot be empty"}))
    end

    test "rejects non-numeric input" do
      result = UserInput.parse_board_id("abc")
      expect(result, to: equal({:error, "jira board id must be a numeric value"}))

      result = UserInput.parse_board_id("12abc")
      expect(result, to: equal({:error, "jira board id must be a numeric value"}))

      result = UserInput.parse_board_id("1.5")
      expect(result, to: equal({:error, "jira board id must be a numeric value"}))
    end
  end

  describe "parse_stories_remaining/1" do
    test "accepts integers greater than zero" do
      {:ok, parsed} = UserInput.parse_stories_remaining("12")

      expect(parsed, to: equal(12))
    end

    test "rejects zero, negatives, and non-integers" do
      for input <- ["0", "-2", "3.2", "whoops"] do
        result = UserInput.parse_stories_remaining(input)

        expect(result, to: be_an_error())
      end
    end
  end

  describe "parse_release_date/2" do
    test "accepts future Fridays without warning" do
      {:ok, parsed, warning} = UserInput.parse_release_date("2026-01-09", ~D[2026-01-01])

      expect(parsed, to: equal(~D[2026-01-09]))
      expect(warning, to: be_nil())
    end

    test "rejects non-ISO date values" do
      any_old_date = ~D[2026-01-01]

      for date_string <- ["2026/01/02", "garbage", ""] do
        result = UserInput.parse_release_date(date_string, any_old_date)

        expect(result, to: be_an_error())
      end
    end

    test "rejects dates that are not in the future" do
      result = UserInput.parse_release_date("2026-01-01", ~D[2026-01-01])
      expect(result, to: be_an_error())

      result = UserInput.parse_release_date("2025-12-31", ~D[2026-01-01])
      expect(result, to: be_an_error())
    end

    test "rounds release dates to the nearest Friday and warns" do
      {:ok, nearest_friday, warning} =
        UserInput.parse_release_date("2026-01-05", ~D[2026-01-01])

      expect(nearest_friday, to: equal(~D[2026-01-02]))

      expect(warning,
        to: equal("Warning: 2026-01-05 is not a Friday; using nearest Friday 2026-01-02.")
      )
    end

    @friday ~D[2026-01-02]
    test "always rounds to the closest friday (at most 3 days before or after)" do
      given_date = ~D[2025-01-01]

      for date_string <- [
            "2026-01-04",
            "2026-01-03",
            "2026-01-02",
            "2026-01-01",
            "2025-12-31",
            "2025-12-30"
          ] do
        {:ok, date, _warning_or_nil} = UserInput.parse_release_date(date_string, given_date)

        expect(date, to: equal(@friday))
      end
    end

    test "doesn't round to the same friday in the same week, if it would be 4+ days away" do
      {:ok, date, _warning} = UserInput.parse_release_date("2025-12-29", ~D[2025-01-01])
      expect(date, to_not: equal(@friday))

      {:ok, date, _warning} = UserInput.parse_release_date("2025-12-29", ~D[2025-01-01])
      expect(date, to_not: equal(@friday))
    end
  end

  describe "parse_percent/1" do
    test "returns the percentage as a float when it can be parsed" do
      {:ok, percent} = UserInput.parse_percent("42")

      expect(percent, to: equal(0.42))
    end

    test "handles optional decimal points" do
      {:ok, percent} = UserInput.parse_percent("42.123")

      expect(percent, to: equal(0.42123))
    end

    test "accepts values outside the range [0-100)" do
      result = UserInput.parse_percent("0")
      expect(result, to_not: be_an_error())

      result = UserInput.parse_percent("99.999")
      expect(result, to_not: be_an_error())
    end

    test "returns an error for values outside the range [0-100)" do
      result = UserInput.parse_percent("-1")
      expect(result, to: be_an_error())

      result = UserInput.parse_percent("100")
      expect(result, to: be_an_error())
    end

    test "returns an error when it cannot be parsed as a percent" do
      result = UserInput.parse_percent("whoopsie")

      expect(result, to: be_an_error())
    end
  end

  describe "parse_list_of_ints/1" do
    test "returns the list when it can be parsed as a comma-separated list" do
      {:ok, velocity} = UserInput.parse_list_of_ints("1,2,3")

      expect(velocity, to: equal([1, 2, 3]))
    end

    test "returns the list when it can be parsed as a whitepace-separated list" do
      {:ok, velocity} = UserInput.parse_list_of_ints("4 5 6")

      expect(velocity, to: equal([4, 5, 6]))
    end

    test "an list that contains negative integers is an error" do
      result = UserInput.parse_list_of_ints("-1")

      expect(result, to: be_an_error())
    end

    test "an list that contains non-integers is an error" do
      result = UserInput.parse_list_of_ints("whoopsie")

      expect(result, to: be_an_error())
    end

    test "an empty list is an error" do
      result = UserInput.parse_list_of_ints("")

      expect(result, to: be_an_error())
    end
  end
end
