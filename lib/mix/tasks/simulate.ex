defmodule Mix.Tasks.Simulate do
  use Mix.Task

  @shortdoc "Runs a Monte Carlo simulation of an engineering team"
  @requirements ["app.start"]
  @num_simulations 100_000

  defmodule UserInput do
    @friday 5

    @doc false
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

  @impl Mix.Task
  def run(_args) do
    board_id = prompt_required("Jira board id: ")
    stories_remaining = prompt_stories_remaining()
    desired_release_date = prompt_release_date()

    IO.puts("")
    IO.puts("Goal : deliver #{stories_remaining} stories before #{desired_release_date}")
    IO.puts("")

    velocity = calculate_historical_velocity!(board_id)

    working_days =
      Date.range(Date.utc_today(), desired_release_date)
      |> Enum.map(&Date.day_of_week/1)
      |> Enum.filter(&(&1 <= 5))
      |> length()

    scenario =
      MonteCarloSimulation.new(
        stories_remaining: stories_remaining,
        velocity: velocity
      )

    days_to_complete_counts =
      1..@num_simulations
      |> Enum.reduce(%{}, fn _simulation, acc ->
        days_to_complete = MonteCarloSimulation.forecast(0, scenario)

        Map.update(acc, days_to_complete, 1, fn existing_count -> existing_count + 1 end)
      end)

    results =
      days_to_complete_counts
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

    IO.puts(
      "We will deliver on-time #{MonteCarloSimulation.percent(on_time, @num_simulations)} % of the time"
    )

    IO.puts(
      "We will deliver late    #{MonteCarloSimulation.percent(late, @num_simulations)} % of the time"
    )

    weekly_distribution =
      Enum.reduce(days_to_complete_counts, %{}, fn {days_elapsed, occurrences}, acc ->
        week_number = div(days_elapsed, 5)

        Map.update(acc, week_number, occurrences, fn existing_count ->
          existing_count + occurrences
        end)
      end)

    IO.puts("")
    IO.puts("Completion distribution by week")

    weekly_distribution
    |> render_weekly_distribution_chart(@num_simulations)
    |> Enum.each(&IO.puts/1)
  end

  @doc false
  def render_weekly_distribution_chart(weekly_distribution, number_simulations, bar_width \\ 40) do
    ["Week | % of simulations"] ++
      (weekly_distribution
       |> Enum.sort_by(fn {week_number, _occurrences} -> week_number end)
       |> Enum.map(fn {week_number, occurrences} ->
         percentage = occurrences / number_simulations * 100

         bar_length =
           percentage
           |> Kernel./(100)
           |> Kernel.*(bar_width)
           |> round()
           |> max(if(occurrences > 0, do: 1, else: 0))
           |> min(bar_width)

         bar = String.duplicate("█", bar_length)

         "#{String.pad_leading(Integer.to_string(week_number), 4)} | #{String.pad_trailing(bar, bar_width)} #{:erlang.float_to_binary(percentage, decimals: 2)}%"
       end))
  end

  # # # Private

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

  defp prompt_stories_remaining do
    prompt_until_valid("Stories to deliver: ", &UserInput.parse_stories_remaining/1)
  end

  defp prompt_release_date do
    prompt_until_valid(
      "Desired release date (YYYY-MM-DD): ",
      &UserInput.parse_release_date/1,
      fn warning ->
        if warning, do: IO.puts(warning)
      end
    )
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
