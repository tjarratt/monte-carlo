defmodule MonteCarloSimulation do
  def forecast(days_thus_far, stories_remaining, tickets_per_week) do
    stories_delivered = Enum.random(tickets_per_week)

    if stories_delivered >= stories_remaining do
      days_thus_far + 5
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


