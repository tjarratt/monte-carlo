defmodule Mix.Tasks.Simulate do
  use Mix.Task

  @shortdoc "Runs a Monte Carlo simulation of an engineering team"
  @requirements ["app.start"]

  @impl Mix.Task
  def run(_args) do
    stories_remaining = 37
    desired_release_date = ~D[2025-09-29]
    num_simulations = 100_000

    board_id =
      case IO.gets("Jira board id: ") do
        :eof ->
          IO.puts("No input received for Jira board ID.")
          System.halt(1)

        value ->
          String.trim(value)
      end

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

    results =
      1..num_simulations
      |> Enum.reduce(%{}, fn _simulation, acc ->
        days_to_complete = MonteCarloSimulation.forecast(0, stories_remaining, tickets_per_week)

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
    IO.puts("We will deliver on-time #{MonteCarloSimulation.percent(on_time, num_simulations)} % of the time")
    IO.puts("We will deliver late    #{MonteCarloSimulation.percent(late, num_simulations)} % of the time")
  end
end
