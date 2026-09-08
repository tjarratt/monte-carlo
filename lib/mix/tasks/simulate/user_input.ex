defmodule Mix.Tasks.Simulate.UserInput do
  @friday 5

  @doc false
  def parse_board_id(input) do
    board_id = String.trim(input)

    cond do
      board_id == "" -> {:error, "jira board id cannot be empty"}
      Regex.match?(~r/^\d+$/, board_id) -> {:ok, board_id}
      true -> {:error, "jira board id must be a numeric value"}
    end
  end

  def parse_stories_remaining(input) do
    case Integer.parse(String.trim(input)) do
      {stories, ""} when stories > 0 -> {:ok, stories}
      _ -> {:error, "stories to deliver must be an integer greater than 0"}
    end
  end

  def parse_release_date(input, today \\ Date.utc_today()) do
    with trimmed when trimmed != "" <- String.trim(input),
         {:ok, release_date} <- Date.from_iso8601(trimmed),
         :gt <- Date.compare(release_date, today) do
      if Date.day_of_week(release_date) == @friday do
        {:ok, release_date, nil}
      else
        rounded_date = nearest_friday(release_date)

        if Date.compare(rounded_date, today) == :gt do
          warning =
            "Warning: #{Date.to_iso8601(release_date)} is not a Friday; using nearest Friday #{Date.to_iso8601(rounded_date)}."

          {:ok, rounded_date, warning}
        else
          {:error, "nearest Friday must be in the future"}
        end
      end
    else
      "" -> {:error, "release date is required"}
      {:error, _reason} -> {:error, "release date must be in YYYY-mm-dd format"}
      :lt -> {:error, "release date must be in the future"}
      :eq -> {:error, "release date must be in the future"}
    end
  end

  defp nearest_friday(date) do
    if Date.day_of_week(date) == @friday do
      date
    else
      days_since_previous_friday = rem(Date.day_of_week(date) - @friday + 7, 7)
      days_until_next_friday = 7 - days_since_previous_friday

      previous_friday = Date.add(date, -days_since_previous_friday)
      next_friday = Date.add(date, days_until_next_friday)

      if days_since_previous_friday <= days_until_next_friday do
        previous_friday
      else
        next_friday
      end
    end
  end
end
