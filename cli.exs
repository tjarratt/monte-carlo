def simulate() do
  stories_remaining = 43
  working_days = 30
  tickets_per_week = [7,8,6,2,4,5,7,9, 12, 12]
  num_simulations = 10_000
  
  results =
    1..num_simulations
    |> Enum.reduce(%{}, fn _day, acc ->
      days_to_complete = MonteCarloSimulation.forecast(0, stories_remaining, tickets_per_week)
  
      Map.update(acc, days_to_complete, 1, fn existing_count -> existing_count + 1 end)
    end)
    |> Map.to_list()
    |> Enum.group_by(fn {days_elapsed, _occurrences} ->
      if days_elapsed <= working_days do
        :on_time
      else
        :late
      end
    end)
  
  on_time = Map.get(results, :on_time, [])
  late = Map.get(results, :late, [])
  
  IO.puts("We will deliver on-time #{MonteCarloSimulation.percent(on_time, num_simulations)} % of the time")
  IO.puts("We will deliver late    #{MonteCarloSimulation.percent(late, num_simulations)} % of the time")
end
