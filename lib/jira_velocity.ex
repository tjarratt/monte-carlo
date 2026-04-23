defmodule JiraVelocity do
  @weeks_to_fetch 10

  def fetch_velocity(board_id) do
    :inets.start()
    :ssl.start()

    with {:ok, normalized_board_id} <- validate_board_id(board_id),
         {:ok, config} <- jira_config(),
         {:ok, filter_id} <- board_filter_id(config, normalized_board_id) do
      Date.utc_today()
      |> week_ranges(@weeks_to_fetch)
      |> Enum.map(&count_completed_stories(config, filter_id, &1))
      |> collect_counts()
    end
  end

  defp validate_board_id(input) do
    board_id =
      input
      |> to_string()
      |> String.trim()

    cond do
      board_id == "" -> {:error, "jira board id cannot be empty"}
      Regex.match?(~r/^\d+$/, board_id) -> {:ok, board_id}
      true -> {:error, "jira board id must be a numeric value"}
    end
  end

  defp jira_config do
    # TODO: add the board_id here too
    base_url = System.get_env("JIRA_BASE_URL", "") |> String.trim_trailing("/")
    email = System.get_env("JIRA_EMAIL", "")
    api_token = System.get_env("JIRA_API_TOKEN", "")

    if Enum.all?([base_url, email, api_token], &(String.trim(&1) != "")) do
      {:ok, %{base_url: base_url, email: email, api_token: api_token}}
    else
      {:error, "set JIRA_BASE_URL, JIRA_EMAIL, and JIRA_API_TOKEN environment variables"}
    end
  end

  defp board_filter_id(config, board_id) do
    path = "/rest/agile/1.0/board/#{board_id}/configuration"

    with {:ok, payload} <- get_json(config, path),
         %{"filter" => %{"id" => filter_id}} <- payload do
      {:ok, filter_id}
    else
      {:error, reason} ->
        {:error, reason}

      unknown ->
        {:error, "could not read Jira board filter for board #{board_id} :: #{inspect(unknown)}"}
    end
  end

  defp count_completed_stories(config, filter_id, {start_date, end_date}) do
    jql =
      "filter = #{filter_id} AND (issuetype = Story OR issuetype = Task) AND statusCategory = Done " <>
        "AND resolved >= \"#{Date.to_iso8601(start_date)}\" " <>
        "AND resolved < \"#{Date.to_iso8601(end_date)}\""

    path = "/rest/api/3/search/jql?jql=#{URI.encode_www_form(jql)}&maxResults=5000"

    with {:ok, payload} <- get_json(config, path),
         issues when is_list(issues) <- Map.get(payload, "issues"),
         total <- length(issues) do
      {:ok, total}
    else
      {:error, reason} ->
        {:error, reason}

      _ ->
        {:error,
         "could not read completed stories for #{Date.to_iso8601(start_date)}..#{Date.to_iso8601(end_date)}"}
    end
  end

  defp get_json(config, path) do
    headers = [
      {~c"Authorization",
       to_charlist("Basic #{Base.encode64("#{config.email}:#{config.api_token}")}")},
      {~c"Accept", ~c"application/json"}
    ]

    request = {to_charlist(config.base_url <> path), headers}

    with {:ok, {{_http_version, status_code, _reason_phrase}, _response_headers, body}}
         when status_code in 200..299 <- :httpc.request(:get, request, [], []),
         {:ok, parsed} <- body |> to_string() |> JSON.decode() do
      {:ok, parsed}
    else
      {:ok, {{_http_version, status_code, _reason_phrase}, _response_headers, body}} ->
        {:error, "jira api request failed with status #{status_code}: #{to_string(body)}"}

      {:error, reason} ->
        {:error, "jira api request failed: #{inspect(reason)}"}
    end
  end

  defp week_ranges(today, week_count) do
    current_week_start = Date.beginning_of_week(today, :monday)

    for week_offset <- Range.new(week_count - 1, 0, -1) do
      end_date = Date.add(current_week_start, -week_offset * 7)
      start_date = Date.add(end_date, -7)
      {start_date, end_date}
    end
  end

  defp collect_counts(results) do
    Enum.reduce_while(results, {:ok, []}, fn
      {:ok, count}, {:ok, counts} -> {:cont, {:ok, [count | counts]}}
      {:error, reason}, _acc -> {:halt, {:error, reason}}
    end)
    |> case do
      {:ok, counts} -> {:ok, Enum.reverse(counts)}
      {:error, reason} -> {:error, reason}
    end
  end
end
