defmodule Mix.Tasks.Simulate.ChartTest do
  use ExUnit.Case, async: true

  describe "render_weekly_distribution_chart/3" do
    test "renders sorted rows with percentages and bars" do
      chart =
        Mix.Tasks.Simulate.render_weekly_distribution_chart(
          %{3 => 25_000, 1 => 50_000, 2 => 25_000},
          100_000,
          10
        )

      assert hd(chart) == "Week | % of simulations"
      assert Enum.at(chart, 1) =~ ~r/^\s*1 \| .+ 50\.00%$/
      assert Enum.at(chart, 2) =~ ~r/^\s*2 \| .+ 25\.00%$/
      assert Enum.at(chart, 3) =~ ~r/^\s*3 \| .+ 25\.00%$/
    end

    test "renders an empty bar for zero-percent weeks" do
      chart =
        Mix.Tasks.Simulate.render_weekly_distribution_chart(
          %{1 => 0, 2 => 100_000},
          100_000,
          10
        )

      assert Enum.at(chart, 1) =~ ~r/^\s*1 \|\s+0\.00%$/
      assert Enum.at(chart, 2) =~ ~r/^\s*2 \| [^ ]+ 100\.00%$/
    end
  end
end
