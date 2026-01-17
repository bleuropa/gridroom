defmodule Gridroom.Gemini.Client do
  @moduledoc """
  HTTP client for the Google Gemini API with Google Search grounding.

  Uses the generateContent endpoint with the google_search tool for
  real-time web grounded responses.
  """

  require Logger

  @default_timeout 60_000
  @base_url "https://generativelanguage.googleapis.com/v1beta"

  @doc """
  Returns the Gemini API configuration.
  """
  def config do
    Application.get_env(:gridroom, :gemini, [])
  end

  @doc """
  Check if the Gemini API is enabled.
  """
  def enabled? do
    config()[:enabled] == true && config()[:api_key] != nil
  end

  @doc """
  Send a grounded request to the Gemini API with Google Search.

  ## Options
  - `:timeout` - Request timeout in ms (default: 60000)
  - `:grounding` - Enable Google Search grounding (default: true)

  ## Returns
  - `{:ok, response}` - Successful response with content and grounding metadata
  - `{:error, reason}` - Error with reason

  ## Response structure
  ```
  %{
    content: "The response text...",
    grounding_chunks: [%{uri: "https://...", title: "Source"}],
    grounding_supports: [...],
    search_queries: ["query1", "query2"]
  }
  ```
  """
  def generate(prompt, opts \\ []) do
    unless enabled?() do
      Logger.warning("Gemini API disabled - set GEMINI_API_KEY and GEMINI_ENABLED=true")
      {:error, :gemini_disabled}
    else
      timeout = Keyword.get(opts, :timeout, @default_timeout)
      grounding = Keyword.get(opts, :grounding, true)

      body = build_request_body(prompt, grounding)
      model = config()[:model] || "gemini-2.5-flash"

      case make_request(model, body, timeout) do
        {:ok, %{status: 200, body: body}} ->
          parse_response(body)

        {:ok, %{status: status, body: body}} ->
          Logger.error("Gemini API error: status=#{status} body=#{inspect(body)}")
          {:error, {:api_error, status, body}}

        {:error, reason} ->
          Logger.error("Gemini API request failed: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  # Build request body with optional Google Search grounding
  defp build_request_body(prompt, grounding) do
    base = %{
      "contents" => [
        %{
          "parts" => [
            %{"text" => prompt}
          ]
        }
      ]
    }

    if grounding do
      Map.put(base, "tools", [%{"google_search" => %{}}])
    else
      base
    end
  end

  defp make_request(model, body, timeout) do
    url = "#{@base_url}/models/#{model}:generateContent"

    headers = [
      {"x-goog-api-key", config()[:api_key]},
      {"content-type", "application/json"}
    ]

    Logger.info("Gemini request to #{url}")

    Req.post(url,
      json: body,
      headers: headers,
      receive_timeout: timeout
    )
  end

  defp parse_response(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, decoded} -> parse_response(decoded)
      {:error, _} -> {:error, :invalid_json}
    end
  end

  defp parse_response(%{"candidates" => [candidate | _]} = _response) do
    content = extract_content(candidate)
    grounding_metadata = candidate["groundingMetadata"] || %{}

    grounding_chunks =
      (grounding_metadata["groundingChunks"] || [])
      |> Enum.map(fn chunk ->
        web = chunk["web"] || %{}
        %{uri: web["uri"], title: web["title"]}
      end)

    grounding_supports = grounding_metadata["groundingSupports"] || []
    search_queries = grounding_metadata["webSearchQueries"] || []

    Logger.info(
      "Gemini response: #{String.length(content)} chars, #{length(grounding_chunks)} sources"
    )

    {:ok,
     %{
       content: content,
       grounding_chunks: grounding_chunks,
       grounding_supports: grounding_supports,
       search_queries: search_queries
     }}
  end

  defp parse_response(%{"error" => error}) do
    Logger.error("Gemini API returned error: #{inspect(error)}")
    {:error, {:api_error, error["code"], error["message"]}}
  end

  defp parse_response(response) do
    Logger.warning("Unexpected Gemini response format: #{inspect(response, limit: 500)}")
    {:error, :unexpected_response_format}
  end

  defp extract_content(%{"content" => %{"parts" => parts}}) when is_list(parts) do
    parts
    |> Enum.map(fn
      %{"text" => text} -> text
      _ -> ""
    end)
    |> Enum.join("")
  end

  defp extract_content(_), do: ""
end
