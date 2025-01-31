defmodule MontecarloSimulationTest do
  use ExUnit.Case
  doctest MontecarloSimulation

  test "greets the world" do
    assert MontecarloSimulation.hello() == :world
  end
end
