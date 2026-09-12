defmodule MonteCarlo.Simulation.Buggy do
  defstruct [:stories_remaining, :velocity, :bug_rates]

  @days_worked_per_week 5

  def new(input_reader: input_reader, stories_remaining: stories_remaining) do
    velocity = input_reader.ask_for(:velocity)
    bug_rates = input_reader.ask_for(:bugs)

    %__MODULE__{
      stories_remaining: stories_remaining,
      velocity: velocity,
      bug_rates: bug_rates
    }
  end

  def new(from_existing: scenario, stories_remaining: stories_remaining) do
    %{scenario | stories_remaining: stories_remaining}
  end

  def forecast(days_thus_far \\ 0, scenario = %__MODULE__{}) do
    # 99 user stories on the wall, 99 user stories
    stories_delivered = Enum.random(scenario.velocity)

    # take one down, pass it around
    newly_created_bugs = Enum.random(scenario.bug_rates)

    # 101 user stories on the wall
    stories_remaining = scenario.stories_remaining + newly_created_bugs - stories_delivered

    if stories_remaining <= 0 do
      days_thus_far + @days_worked_per_week
    else
      # simulate another week until we're done
      new_scenario = new(from_existing: scenario, stories_remaining: stories_remaining)

      forecast(days_thus_far + @days_worked_per_week, new_scenario)
    end
  end
end
