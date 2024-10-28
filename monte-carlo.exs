defmodule MonteCarlo do
  def forecast(days_thus_far, stories_remaining, tickets_per_week) do
    stories_delivered = Enum.random(tickets_per_week)

    if stories_delivered >= stories_remaining do
      days_thus_far
    else
      forecast(days_thus_far + 5, stories_remaining - stories_delivered, tickets_per_week)
    end
  end

  def percent(outcomes, number_simulations) do
    outcomes
    |> Enum.map(fn {_days_elapsed, occurrences} -> occurrences end)
    |> Enum.sum()
    |> Kernel./(number_simulations)
    |> Kernel.*(100)
    |> Float.round(2)
  end
end

stories_remaining = 13
working_days = 25
tickets_per_week = 3..5
num_simulations = 10_000

results =
  1..num_simulations
  |> Enum.reduce(%{}, fn _day, acc ->
    days_to_complete = MonteCarlo.forecast(5, stories_remaining, tickets_per_week)

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

IO.puts("We will deliver on-time #{MonteCarlo.percent(on_time, num_simulations)} % of the time")
IO.puts("We will deliver late    #{MonteCarlo.percent(late, num_simulations)} % of the time")
