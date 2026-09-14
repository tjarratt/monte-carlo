defmodule Mix.Tasks.Simulate.BarChartTest do
  # @related [subject](lib/mix/tasks/simulate/bar_chart.ex)
  use ExUnit.Case, async: true
  use Expect

  alias Mix.Tasks.Simulate.BarChart

  describe "render_weekly_distribution_chart/3" do
    test "renders sorted rows with percentages and bars" do
      [header, line1, line2, line3] =
        BarChart.render(
          %{3 => 25_000, 1 => 50_000, 2 => 25_000},
          100_000,
          10
        )

      expect(header, to: equal("Week | % of simulations"))
      expect(line1, to: match_regex(~r/^\s*1 \| .+ 50\.00%$/))
      expect(line2, to: match_regex(~r/^\s*2 \| .+ 25\.00%$/))
      expect(line3, to: match_regex(~r/^\s*3 \| .+ 25\.00%$/))
    end

    test "renders correct week numbers when the year wraps around" do
      [header, line1, line2, line3] =
        BarChart.render(
          %{51 => 30_000, 52 => 50_000, 53 => 20_000},
          100_000,
          10
        )

      expect(header, to: equal("Week | % of simulations"))
      expect(line1, to: match_regex(~r/^\s*51 \| .+ 30\.00%$/))
      expect(line2, to: match_regex(~r/^\s*52 \| .+ 50\.00%$/))
      expect(line3, to: match_regex(~r/^\s*1 \| .+ 20\.00%$/))
    end

    test "renders an empty bar for zero-percent weeks" do
      [_header, line1, line2] =
        BarChart.render(
          %{1 => 0, 2 => 100_000},
          100_000,
          10
        )

      expect(line1, to: match_regex(~r/^\s*1 \|\s+0\.00%$/))
      expect(line2, to: match_regex(~r/^\s*2 \| [^ ]+ 100\.00%$/))
    end
  end
end
