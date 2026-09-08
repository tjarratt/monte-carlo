defmodule Mix.Tasks.Simulate.BarChart do
  def render(weekly_distribution, number_simulations, bar_width \\ 40) do
    ["Week | % of simulations"] ++
      (weekly_distribution
       |> Enum.sort_by(fn {week_number, _occurrences} -> week_number end)
       |> Enum.map(fn {week_number, occurrences} ->
         percentage = occurrences / number_simulations * 100
         base_bar_length = if occurrences > 0, do: 1, else: 0
         scaled_bar_length = round(percentage * bar_width / 100)

         bar_length = scaled_bar_length |> max(base_bar_length) |> min(bar_width)
         bar = String.duplicate("█", bar_length)
         week_label = String.pad_leading(Integer.to_string(week_number), 4)
         padded_bar = String.pad_trailing(bar, bar_width)
         formatted_percentage = :erlang.float_to_binary(percentage, decimals: 2)

         "#{week_label} | #{padded_bar} #{formatted_percentage}%"
       end))
  end
end
