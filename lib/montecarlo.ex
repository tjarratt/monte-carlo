defmodule MonteCarlo.Simulation do
  def percent(outcomes, number_simulations) do
    outcomes
    |> Enum.map(fn {_days_elapsed, occurrences} -> occurrences end)
    |> Enum.sum()
    |> Kernel./(number_simulations)
    |> Kernel.*(100)
    |> Float.round(2)
  end
end
