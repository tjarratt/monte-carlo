defmodule MonteCarlo.Simulation.BatchRelease do
  @moduledoc """
    Simulates an engineering team that delivers work periodically in batches (eg: daily, weekly, monthly)

    Rather than deploying directly to production for each commit that passes CI,
    this team periodically merges their development branch into their main/prod branch.

    Each deployment of a batch can fail (with a configurably rate). When a deployment fails,
    all the work in that batch needs to wait for the next release before it can be deployed.

    This assumes that each release is equally likely to fail. In practice, larger
    batches result in more risk, but this doesn't model that level of complexity.
  """

  defstruct [:stories_remaining, :velocity, :release_frequency, :rollback_rate, :batched]

  def new(input_reader: input_reader, stories_remaining: stories_remaining, velocity: velocity) do
    release_frequency = input_reader.ask_for(:release_frequency)
    rollback_rate = input_reader.ask_for(:rollback_rate)

    %__MODULE__{
      stories_remaining: stories_remaining,
      velocity: velocity,
      release_frequency: release_frequency,
      rollback_rate: rollback_rate,
      batched: 0
    }
  end

  def new(from: scenario, stories_remaining: stories_remaining) do
    %{scenario | stories_remaining: stories_remaining}
  end

  def forecast(days_thus_far \\ 0, scenario = %__MODULE__{release_frequency: :daily}) do
    # for each day of the week ...
    {stories_delivered, scenario} =
      1..MonteCarlo.days_worked_per_week()
      |> Enum.reduce({0, scenario}, fn _day, {acc, state} ->
        # deliver some amount of work plus whatever was in the previously unreleased batch
        # rounding down reduces velocity a touch, but let's assume some overhead coordinating and testing releases
        delivered_today =
          scenario.velocity |> Enum.random() |> (&(&1 / 5.0)).() |> round() |> max(1)

        batch = delivered_today + state.batched

        # if today's batch failed
        if :rand.uniform(100) < scenario.rollback_rate do
          # -> hold onto the batch for tomorrow
          {acc, %{state | batched: batch}}
        else
          # -> otherwise, we delivered something, empty the batch
          {acc + batch, %{state | batched: 0}}
        end
      end)

    if scenario.stories_remaining - stories_delivered <= 0 do
      days_thus_far + MonteCarlo.days_worked_per_week()
    else
      new_scenario =
        new(from: scenario, stories_remaining: scenario.stories_remaining - stories_delivered)

      forecast(days_thus_far + MonteCarlo.days_worked_per_week(), new_scenario)
    end
  end
end
