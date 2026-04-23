defmodule Mix.Tasks.Simulate.InputCache do
  @default_cache_file "tmp/simulate_inputs.json"

  def read(key) do
    path = cache_file()

    with {:ok, content} <- File.read(path),
         {:ok, map} <- JSON.decode(content) do
      Map.get(map, to_string(key))
    else
      _ -> nil
    end
  end

  def write(key, value) do
    path = cache_file()
    existing = read_all(path)
    updated = Map.put(existing, to_string(key), to_string(value))
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, JSON.encode!(updated))
  end

  defp cache_file do
    Application.get_env(:montecarlo_simulation, :input_cache_file, @default_cache_file)
  end

  defp read_all(path) do
    with {:ok, content} <- File.read(path),
         {:ok, map} <- JSON.decode(content) do
      map
    else
      _ -> %{}
    end
  end
end
