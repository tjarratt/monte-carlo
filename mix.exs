defmodule MontecarloSimulation.MixProject do
  use Mix.Project

  def project do
    [
      app: :montecarlo_simulation,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :inets, :ssl]
    ]
  end

  defp deps do
    [
      {:expect, "~> 3.0", only: [:test], runtime: false},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp package() do
    [
      files: ~w[
        README.*
        lib/**/*.ex
        LICENSE
        mix.exs
      ],
      licenses: ["MIT"],
      maintainers: ["Tim Jarratt"]
    ]
  end
end
