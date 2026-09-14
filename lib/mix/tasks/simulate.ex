defmodule Mix.Tasks.Simulate do
  use Mix.Task

  @shortdoc "Runs a Monte Carlo simulation of an engineering team"

  @requirements ["app.start"]

  alias Mix.Tasks.Simulate.BarChart
  alias Mix.Tasks.Simulate.InputCache
  alias Mix.Tasks.Simulate.UserInput

  @impl Mix.Task
  def run(args) do
    flags = parse_flags!(args)
    strategy = Keyword.fetch!(flags, :strategy)
    velocity_strategy = Keyword.fetch!(flags, :velocity_from)

    stories_remaining = ask_for(:stories_to_deliver)
    desired_release_date = ask_for(:desired_release_date)
    velocity = ask_for(:velocity, strategy: velocity_strategy)

    scenario =
      strategy.new(
        input_reader: __MODULE__,
        stories_remaining: stories_remaining,
        velocity: velocity
      )

    IO.puts("")
    IO.puts("Goal : deliver #{stories_remaining} stories before #{desired_release_date}")
    IO.puts("")

    results = MonteCarlo.run(strategy, scenario, desired_release_date)

    IO.puts("Results")
    IO.puts("-------")
    IO.puts("")
    IO.puts("We are on-time #{results.on_time} % of the time")
    IO.puts("We are late    #{results.late} % of the time")
    IO.puts("")
    IO.puts("Current week is #{results.current_week}")
    IO.puts("Most likely delivery is by end of week #{results.most_likely_week}")
    IO.puts("")

    results.distribution_by_week
    |> BarChart.render(results.num_simulations)
    |> Enum.each(fn line -> IO.puts(line) end)
  end

  # # # Command-line Flags

  defp parse_flags!(args) do
    flags =
      args
      |> Enum.chunk_every(2)
      |> Enum.reduce(%{}, fn [flag, value], acc -> Map.put(acc, flag, value) end)

    scenario_strategy = Map.get(flags, "--strategy") |> strategy_from!()
    velocity_strategy = Map.get(flags, "--velocity-from") |> velocity_strategy_from!()

    [strategy: scenario_strategy, velocity_from: velocity_strategy]
  end

  defp strategy_from!(nil), do: MonteCarlo.Simulation.Simple
  defp strategy_from!("simple"), do: MonteCarlo.Simulation.Simple
  defp strategy_from!("buggy"), do: MonteCarlo.Simulation.Buggy
  defp strategy_from!(unknown), do: raise("Unknown strategy '#{unknown}'")

  defp velocity_strategy_from!(nil), do: :from_jira
  defp velocity_strategy_from!("jira"), do: :from_jira

  defp velocity_strategy_from!(unknown),
    do:
      raise("""
      Unknown value for flag --velocity-from : '#{unknown}'

      Supported values: [jira, stdin]

      """)

  # # # User Input
  def ask_for(input, opts \\ [])

  def ask_for(:velocity, strategy: :from_jira) do
    IO.puts("Calculating historical velocity from jira ...")

    case JiraVelocity.fetch_velocity() do
      {:ok, weekly_counts} ->
        IO.puts("Using calculated velocity from jira: #{inspect(weekly_counts)}")
        weekly_counts

      {:error, reason} ->
        IO.puts("Could not fetch Jira weekly velocity: #{reason}")
        System.halt(1)
    end
  end

  def ask_for(:bugs, _opts) do
    prompt_until_valid(
      "Percentage of work delivered that has bugs",
      :bug_rate,
      &UserInput.parse_percent/1
    )
  end

  def ask_for(:stories_to_deliver, _opts) do
    prompt_until_valid(
      "Stories to deliver",
      :stories_remaining,
      &UserInput.parse_stories_remaining/1
    )
  end

  def ask_for(:desired_release_date, _opts) do
    prompt_until_valid(
      "Desired release date (YYYY-MM-DD)",
      :release_date,
      &UserInput.parse_release_date/1,
      fn warning ->
        if warning, do: IO.puts(warning)
      end
    )
  end

  defp prompt_until_valid(prompt_label, cache_key, parser, on_parsed \\ fn _ -> :ok end) do
    cached = InputCache.read(cache_key)

    full_prompt =
      if cached do
        "#{prompt_label} [#{cached}]: "
      else
        "#{prompt_label}: "
      end

    raw = get_input(full_prompt)
    input = if raw == "" && !is_nil(cached), do: cached, else: raw

    case parser.(input) do
      {:ok, parsed_value} ->
        InputCache.write(cache_key, input)
        on_parsed.(nil)
        parsed_value

      {:ok, parsed_value, warning} ->
        InputCache.write(cache_key, input)
        on_parsed.(warning)
        parsed_value

      {:error, reason} ->
        IO.puts("Invalid input: #{reason}")
        prompt_until_valid(prompt_label, cache_key, parser, on_parsed)
    end
  end

  defp get_input(prompt) do
    case IO.gets(prompt) do
      :eof ->
        IO.puts("No input received.")
        System.halt(1)

      value ->
        String.trim(value)
    end
  end
end
