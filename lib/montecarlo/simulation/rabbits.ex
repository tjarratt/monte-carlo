defmodule MonteCarlo.Simulation.Rabbits do
  defstruct [:population, :birth_rates, :death_rates]

  def new(population: population, birth_rates: birth_rates, death_rates: death_rates) do
    %__MODULE__{
      population: population,
      birth_rates: birth_rates,
      death_rates: death_rates
    }
  end

  def forecast(years_to_compute \\ 5, scenario = %__MODULE__{}) do
    births = scenario.population * Enum.random(scenario.birth_rates)
    deaths = scenario.population * Enum.random(scenario.death_rates)

    new_population = scenario.population + births - deaths

    if years_to_compute == 0 do
      new_population
    else
      forecast(
        years_to_compute - 1,
        %{scenario | population: new_population}
      )
    end
  end
end
