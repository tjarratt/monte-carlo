defmodule MonteCarlo.Simulation.Buggy do
  @moduledoc """
    Simulates an engineering team that delivers buggy work directly to production (eg: with CI/CD).

    This is a relatively average engineering team. They deliver work reliably, but reliably
    we can count on some percentage of that work to have bugs.

    This simulates a week at a time. Each week some work is delivered based on historical
    measurements of velocity, and some new work is created (eg: from reported bugs). The
    team continues until all these bugs are completed.

    This model assumes these bugs reported are URGENT and need to be worked on immediately.
    This also assumes that we're discovering the bugs soon after we deploy, and that fixing
    a bug is roughly the same amount of effort as delivering some work.

    eg: if a team can deliver 5 user stories in a week, they could also fix 5 bugs in a week.
  """

  defstruct [:stories_remaining, :velocity, :bug_rate]

  def new(input_reader: input_reader, stories_remaining: stories_remaining, velocity: velocity) do
    bug_rate = input_reader.ask_for(:bugs)

    %__MODULE__{
      stories_remaining: stories_remaining,
      velocity: velocity,
      bug_rate: bug_rate
    }
  end

  def new(from_existing: scenario, stories_remaining: stories_remaining) do
    %{scenario | stories_remaining: stories_remaining}
  end

  def forecast(days_thus_far \\ 0, scenario = %__MODULE__{}) do
    # 99 user stories on the wall, 99 user stories
    stories_delivered = Enum.random(scenario.velocity)

    # take one down, pass it around
    newly_created_bugs = stories_delivered * scenario.bug_rate

    # 101 user stories on the wall
    stories_remaining = scenario.stories_remaining + newly_created_bugs - stories_delivered

    if stories_remaining <= 0 do
      days_thus_far + MonteCarlo.days_worked_per_week()
    else
      # simulate another week until we're done
      new_scenario = new(from_existing: scenario, stories_remaining: stories_remaining)

      forecast(days_thus_far + MonteCarlo.days_worked_per_week(), new_scenario)
    end
  end
end
