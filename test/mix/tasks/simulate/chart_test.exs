defmodule Mix.Tasks.Simulate.ChartTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Simulate.BarChart

  describe "render_weekly_distribution_chart/3" do
    test "renders sorted rows with percentages and bars" do
      [header, line1, line2, line3] =
        BarChart.render(
          %{3 => 25_000, 1 => 50_000, 2 => 25_000},
          100_000,
          10
        )

      assert header == "Week | % of simulations"
      assert line1 =~ ~r/^\s*1 \| .+ 50\.00%$/
      assert line2 =~ ~r/^\s*2 \| .+ 25\.00%$/
      assert line3 =~ ~r/^\s*3 \| .+ 25\.00%$/
    end

    test "renders an empty bar for zero-percent weeks" do
      [_header, line1, line2] =
        BarChart.render(
          %{1 => 0, 2 => 100_000},
          100_000,
          10
        )

      assert line1 =~ ~r/^\s*1 \|\s+0\.00%$/
      assert line2 =~ ~r/^\s*2 \| [^ ]+ 100\.00%$/
    end
  end
end
