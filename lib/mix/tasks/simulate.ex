defmodule Mix.Tasks.Simulate do
  use Mix.Task

  @shortdoc "Runs a Monte Carlo simulation of an engineering team"
  @requirements ["app.start"]
  @num_simulations 100_000

  alias Mix.Tasks.Simulate.BarChart
  alias Mix.Tasks.Simulate.InputCache
  alias Mix.Tasks.Simulate.UserInput

  @impl Mix.Task
  def run(_args) do
    board_id = prompt_board_id()
    stories_remaining = prompt_stories_remaining()
    desired_release_date = prompt_release_date()
    velocity = calculate_historical_velocity!(board_id)
    working_days = working_days_until(desired_release_date)

    IO.puts("")
    IO.puts("Goal : deliver #{stories_remaining} stories before #{desired_release_date}")
    IO.puts("")

    scenario =
      MonteCarlo.Simulation.new(
        stories_remaining: stories_remaining,
        velocity: velocity
      )

    simulations =
      1..@num_simulations
      |> Enum.reduce(%{}, fn _simulation, acc ->
        days_to_complete = MonteCarlo.Simulation.forecast(0, scenario)

        Map.update(acc, days_to_complete, 1, fn existing_count -> existing_count + 1 end)
      end)

    results =
      simulations
      |> Enum.group_by(fn {days_elapsed, _occurrences} ->
        if days_elapsed <= working_days do
          :on_time
        else
          :late
        end
      end)

    on_time = Map.get(results, :on_time, []) |> MonteCarlo.Simulation.percent(@num_simulations)
    late = Map.get(results, :late, []) |> MonteCarlo.Simulation.percent(@num_simulations)

    current_week = current_week()

    week_distribution =
      Enum.reduce(simulations, %{}, fn {days_elapsed, occurrences}, acc ->
        week_number = current_week + max(div(days_elapsed - 1, 5) + 1, 1)

        Map.update(acc, week_number, occurrences, fn existing_count ->
          existing_count + occurrences
        end)
      end)

    IO.puts("Results")
    IO.puts("-------")
    IO.puts("")
    IO.puts("We are on-time #{on_time} % of the time")
    IO.puts("We are late    #{late} % of the time")
    IO.puts("")
    IO.puts("Current week is #{current_week}")
    IO.puts("Most likely delivery is by end of week #{most_likely(week_distribution)}")
    IO.puts("")

    week_distribution
    |> BarChart.render(@num_simulations)
    |> Enum.each(fn line -> IO.puts(line) end)
  end

  # # # Private

  defp current_week() do
    {_year, week_number} = :calendar.iso_week_number()
    week_number
  end

  defp working_days_until(date) do
    Date.range(Date.utc_today(), date)
    |> Enum.map(&Date.day_of_week/1)
    |> Enum.filter(&(&1 <= 5))
    |> length()
  end

  defp most_likely(weekly_distributions) do
    weekly_distributions |> Enum.max_by(&elem(&1, 1)) |> elem(0)
  end

  defp calculate_historical_velocity!(board_id) do
    case JiraVelocity.fetch_velocity(board_id) do
      {:ok, weekly_counts} ->
        IO.puts("Using calculated velocity from jira: #{inspect(weekly_counts)}")
        weekly_counts

      {:error, reason} ->
        IO.puts("Could not fetch Jira weekly velocity: #{reason}")
        System.halt(1)
    end
  end

  # # # User Input

  defp prompt_board_id do
    prompt_until_valid("Jira board id", :board_id, &UserInput.parse_board_id/1)
  end

  defp prompt_stories_remaining do
    prompt_until_valid(
      "Stories to deliver",
      :stories_remaining,
      &UserInput.parse_stories_remaining/1
    )
  end

  defp prompt_release_date do
    prompt_until_valid(
      "Desired release date (YYYY-MM-DD)",
      :release_date,
      &UserInput.parse_release_date/1,
      fn warning ->
        if warning, do: IO.puts(warning)
      end
    )
  end

  defp prompt_until_valid(prompt_label, cache_key, parser, on_parsed \\ fn _ -> :ok end) do
    cached = InputCache.read(cache_key)

    full_prompt =
      if cached do
        "#{prompt_label} [#{cached}]: "
      else
        "#{prompt_label}: "
      end

    raw = get_input(full_prompt)
    input = if raw == "" && !is_nil(cached), do: cached, else: raw

    case parser.(input) do
      {:ok, parsed_value} ->
        InputCache.write(cache_key, input)
        on_parsed.(nil)
        parsed_value

      {:ok, parsed_value, warning} ->
        InputCache.write(cache_key, input)
        on_parsed.(warning)
        parsed_value

      {:error, reason} ->
        IO.puts("Invalid input: #{reason}")
        prompt_until_valid(prompt_label, cache_key, parser, on_parsed)
    end
  end

  defp get_input(prompt) do
    case IO.gets(prompt) do
      :eof ->
        IO.puts("No input received.")
        System.halt(1)

      value ->
        String.trim(value)
    end
  end
end
