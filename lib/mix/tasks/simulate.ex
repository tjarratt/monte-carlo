defmodule Mix.Tasks.Simulate do
  use Mix.Task

  @shortdoc "Runs a Monte Carlo simulation of an engineering team"
  @requirements ["app.start"]
  @friday 5
  @num_simulations 100_000

  @impl Mix.Task
  def run(_args) do
    stories_remaining = prompt_stories_remaining()
    desired_release_date = prompt_release_date()

    board_id = prompt_required("Jira board id: ")

    tickets_per_week =
      case JiraVelocity.fetch_velocity(board_id) do
        {:ok, weekly_counts} ->
          IO.puts("Using calculated velocity from jira: #{inspect(weekly_counts)}")
          weekly_counts

        {:error, reason} ->
          IO.puts("Could not fetch Jira weekly velocity: #{reason}")
          System.halt(1)
      end

    working_days =
      Date.range(Date.utc_today(), desired_release_date)
      |> Enum.map(&Date.day_of_week/1)
      |> Enum.filter(&(&1 <= 5))
      |> length()

    scenario =
      MonteCarloSimulation.new(
        stories_remaining: stories_remaining,
        velocity: tickets_per_week
      )

    results =
      1..@num_simulations
      |> Enum.reduce(%{}, fn _simulation, acc ->
        days_to_complete = MonteCarloSimulation.forecast(0, scenario)

        Map.update(acc, days_to_complete, 1, fn existing_count -> existing_count + 1 end)
      end)
      |> Map.to_list()
      |> Enum.group_by(fn {days_elapsed, _occurrences} ->
        if days_elapsed <= working_days do
          :on_time
        else
          :late
        end
      end)

    on_time = Map.get(results, :on_time, [])
    late = Map.get(results, :late, [])

    IO.puts("Goal : deliver #{stories_remaining} stories before #{desired_release_date}")
    IO.puts("")

    IO.puts(
      "We will deliver on-time #{MonteCarloSimulation.percent(on_time, @num_simulations)} % of the time"
    )

    IO.puts(
      "We will deliver late    #{MonteCarloSimulation.percent(late, @num_simulations)} % of the time"
    )
  end

  # # # User Input

  defp prompt_stories_remaining do
    prompt_until_valid("Stories to deliver: ", &parse_stories_remaining/1)
  end

  @doc false
  def parse_stories_remaining(input) do
    case Integer.parse(String.trim(input)) do
      {stories, ""} when stories > 0 -> {:ok, stories}
      _ -> {:error, "stories to deliver must be an integer greater than 0"}
    end
  end

  defp prompt_release_date do
    prompt_until_valid("Desired release date (YYYY-MM-DD): ", &parse_release_date/1, fn warning ->
      if warning, do: IO.puts(warning)
    end)
  end

  @doc false
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
      {:error, _reason} -> {:error, "release date must be in YYYY-MM-DD format"}
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

  defp prompt_until_valid(prompt, parser, on_parsed \\ fn _ -> :ok end) do
    value = prompt_required(prompt)

    case parser.(value) do
      {:ok, parsed_value} ->
        on_parsed.(nil)
        parsed_value

      {:ok, parsed_value, warning} ->
        on_parsed.(warning)
        parsed_value

      {:error, reason} ->
        IO.puts("Invalid input: #{reason}")
        prompt_until_valid(prompt, parser, on_parsed)
    end
  end

  defp prompt_required(prompt) do
    case IO.gets(prompt) do
      :eof ->
        IO.puts("No input received.")
        System.halt(1)

      value ->
        String.trim(value)
    end
  end
end
