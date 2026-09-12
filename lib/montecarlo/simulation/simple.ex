defmodule MonteCarlo.Simulation.Simple do
  defstruct [:stories_remaining, :velocity]

  @days_worked_per_week 5

  def new(input_reader: input_reader, stories_remaining: stories_remaining) do
    velocity = input_reader.ask_for(:velocity)

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
      days_thus_far + @days_worked_per_week
    else
      # simulate another week until we are done
      scenario =
        new(
          from: scenario,
          stories_remaining: scenario.stories_remaining - stories_delivered
        )

      forecast(days_thus_far + @days_worked_per_week, scenario)
    end
  end
end
