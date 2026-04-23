defmodule MonteCarloSimulation do
  defstruct [:stories_remaining, :velocity]

  def new(stories_remaining: stories_remaining, velocity: velocity) do
    %__MODULE__{
      stories_remaining: stories_remaining,
      velocity: velocity
    }
  end

  def forecast(days_thus_far, scenario = %__MODULE__{}) do
    stories_delivered = Enum.random(scenario.velocity)

    if stories_delivered >= scenario.stories_remaining do
      # we're done, yield the total number of days it took
      days_thus_far + 5
    else
      # simulate another week until we are done
      scenario =
        new(
          stories_remaining: scenario.stories_remaining - stories_delivered,
          velocity: scenario.velocity
        )

      forecast(days_thus_far + 5, scenario)
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
