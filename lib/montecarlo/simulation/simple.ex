defmodule MonteCarlo.Simulation.Simple do
  @moduledoc """
    Simulates a engineering team that delivers work directly to production (eg: with CI/CD).

    This is a high-performing engineering team that doesn't have very many bugs, because
    they keep their quality very high.

    This simulates a week at a time. Each week some work is delivered based on historical
    measurements of user stories delivered by week.

    A week is a relatively good measure of time for this, because it results in lower volatility,
    and we get a good tradeoff between accuracy of estimates and ease of collecting the data.

    If you need to know which precise DAY something will be done, this won't work for you.
    But in practice, knowing which week something will occur is typically good enough for the business.
  """

  defstruct [:stories_remaining, :velocity]

  def new(input_reader: _input_reader, stories_remaining: stories_remaining, velocity: velocity) do
    %__MODULE__{
      stories_remaining: stories_remaining,
      velocity: velocity
    }
  end

  def new(from: simulation, stories_remaining: stories_remaining) do
    %{simulation | stories_remaining: stories_remaining}
  end

  def forecast(days_thus_far \\ 0, scenario = %__MODULE__{}) do
    stories_delivered = Enum.random(scenario.velocity)

    if stories_delivered >= scenario.stories_remaining do
      # we're done, yield the total number of days it took
      days_thus_far + MonteCarlo.days_worked_per_week()
    else
      # simulate another week until we are done
      scenario =
        new(
          from: scenario,
          stories_remaining: scenario.stories_remaining - stories_delivered
        )

      forecast(days_thus_far + MonteCarlo.days_worked_per_week(), scenario)
    end
  end
end
