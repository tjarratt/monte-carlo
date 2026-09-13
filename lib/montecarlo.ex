defmodule MonteCarlo do
  @moduledoc "Provides a means to run monte-carlo simulations of an engineering team delivering software"

  @num_simulations 100_000

  defmodule Results do
    @moduledoc """
      Represents the results of running a given scenario against a desired release date.

      The list of `outcomes` contains the results of each simulation run. Each outcome is
      a tuple containing `{number_of_days_to_complete, number_of_occurrences}`. A greater number
      of occurrences for an outcome correlates with a greater likelihood of that occurring.

      Assuming we ran 100 simulations, and 25 of which were on-time, we could represent that thusly :

      ```
      %MonteCarlo.Results{
        outcomes: [{24, 25}, {32, 25}, {40, 25}, {60, 25}],
        on_time: 25.00,
        late: 75.00,
        num_simulations: 100,
        current_week: 7,
        most_likely_week: 39
      }
      ```
    """
    defstruct [
      :num_simulations,
      :raw_outcomes,
      :on_time,
      :late,
      :current_week,
      :most_likely_week,
      :distribution_by_week
    ]
  end

  def run(strategy, scenario, desired_release_date) do
    working_days = working_days_until(desired_release_date)

    simulations =
      1..@num_simulations
      |> Enum.reduce(%{}, fn _index, acc ->
        days_to_complete = strategy.forecast(scenario)

        Map.update(acc, days_to_complete, 1, fn existing_count -> existing_count + 1 end)
      end)

    outcomes =
      simulations
      |> Enum.group_by(fn {days_elapsed, _occurrences} ->
        if days_elapsed <= working_days do
          :on_time
        else
          :late
        end
      end)

    on_time = Map.get(outcomes, :on_time, []) |> percent(@num_simulations)
    late = Map.get(outcomes, :late, []) |> percent(@num_simulations)

    current_week = current_week()

    distribution_by_week =
      Enum.reduce(simulations, %{}, fn {days_elapsed, occurrences}, acc ->
        week_number = current_week + max(div(days_elapsed - 1, 5) + 1, 1)

        Map.update(acc, week_number, occurrences, fn existing_count ->
          existing_count + occurrences
        end)
      end)

    most_likely_week = most_likely(distribution_by_week)

    %Results{
      num_simulations: @num_simulations,
      raw_outcomes: outcomes,
      on_time: on_time,
      late: late,
      current_week: current_week,
      most_likely_week: most_likely_week,
      distribution_by_week: distribution_by_week
    }
  end

  def percent(outcomes, num_simulations) do
    outcomes
    |> Enum.map(fn {_days_elapsed, occurrences} -> occurrences end)
    |> Enum.sum()
    |> Kernel./(num_simulations)
    |> Kernel.*(100)
    |> Float.round(2)
  end

  # # #

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
end
