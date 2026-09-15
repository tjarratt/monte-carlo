defmodule Mix.Tasks.Simulate.BarChart do
  # @related [tests](test/mix/tasks/simulate/bar_chart_test.exs)
  def render(weekly_distribution, number_simulations, bar_width \\ 40) do
    ["Week | % of simulations"] ++
      (weekly_distribution
       |> Enum.sort_by(fn {week_number, _occurrences} -> week_number end)
       |> Enum.map(fn {week_number, occurrences} ->
         percentage = 100.0 * occurrences / number_simulations
         base_bar_length = if occurrences > 0, do: 1, else: 0
         scaled_bar_length = round(percentage * bar_width / 40.0)

         bar_length = scaled_bar_length |> max(base_bar_length) |> min(bar_width)
         bar = String.duplicate("█", bar_length)

         week_label =
           week_number |> handle_end_of_year() |> Integer.to_string() |> String.pad_leading(4)

         formatted_percentage = :erlang.float_to_binary(percentage, decimals: 3)
         padded_bar = String.pad_trailing(bar, bar_width - String.length(formatted_percentage))

         "#{week_label} | #{padded_bar} #{formatted_percentage}%"
       end))
  end

  # this is slightly incorrect, because some years have 53 weeks, but we're close enough
  defp handle_end_of_year(int) when int <= 52, do: int
  defp handle_end_of_year(int) when int > 52, do: rem(int, 52)
end
