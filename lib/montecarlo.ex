defmodule MonteCarlo do
  def percent(outcomes, num_simulations) do
    outcomes
    |> Enum.map(fn {_days_elapsed, occurrences} -> occurrences end)
    |> Enum.sum()
    |> Kernel./(num_simulations)
    |> Kernel.*(100)
    |> Float.round(2)
  end
end
