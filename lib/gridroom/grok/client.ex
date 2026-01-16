defmodule Gridroom.Grok.Client do
  @moduledoc """
  HTTP client for the xAI Grok API.

  Uses the chat completions endpoint with tools for search functionality.
  """

  require Logger

  @default_timeout 120_000

  @doc """
  Returns the Grok API configuration.
  """
  def config do
    Application.get_env(:gridroom, :grok, [])
  end

  @doc """
  Check if the Grok API is enabled.
  """
  def enabled? do
    config()[:enabled] == true && config()[:api_key] != nil
  end

  @doc """
  Send a chat request to the Grok API with optional tools.

  ## Options
  - `:tools` - List of tool names to enable (e.g., ["web_search", "x_search"])
  - `:timeout` - Request timeout in ms (default: 30000)

  ## Returns
  - `{:ok, response}` - Successful response with content and citations
  - `{:error, reason}` - Error with reason
  """
  def chat(prompt, opts \\ []) do
    Logger.info("Grok.Client.chat called, enabled=#{enabled?()}, has_key=#{config()[:api_key] != nil}")

    unless enabled?() do
      Logger.warning("Grok API disabled - set XAI_API_KEY and GROK_ENABLED=true")
      {:error, :grok_disabled}
    else
      tools = Keyword.get(opts, :tools, [])
      timeout = Keyword.get(opts, :timeout, @default_timeout)

      # Use /responses endpoint for search tools, /chat/completions otherwise
      has_search = has_search_tools?(tools)
      Logger.info("Grok tools=#{inspect(tools)}, has_search_tools=#{has_search}")

      {endpoint, body} =
        if has_search do
          {"/responses", build_responses_body(prompt, tools)}
        else
          {"/chat/completions", build_request_body(prompt, tools)}
        end

      Logger.info("Grok request to #{endpoint}")

      case make_request(endpoint, body, timeout) do
        {:ok, %{status: 200, body: body}} ->
          response_keys = if is_map(body), do: Map.keys(body), else: "not_a_map"
          Logger.info("Grok API success, response keys: #{inspect(response_keys)}")
          parse_response(body)

        {:ok, %{status: status, body: body}} ->
          Logger.error("Grok API error: status=#{status} body=#{inspect(body)}")
          {:error, {:api_error, status, body}}

        {:error, reason} ->
          Logger.error("Grok API request failed: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  defp has_search_tools?(tools) do
    Enum.any?(tools, &(&1 in ["web_search", "x_search"]))
  end

  @doc """
  Fetch trending topics using X search.
  """
  def fetch_trends do
    prompt = """
    Search X for trending topics and return 10-12 DIVERSE conversation starters.

    CRITICAL: You MUST use the search tool to find REAL trending content. Do NOT make up topics.

    MANDATORY DIVERSITY - You MUST include topics from ALL these categories (1-2 each):
    1. TECHNOLOGY (not just AI): gadgets, apps, internet culture, cybersecurity
    2. SCIENCE: space, health, environment, discoveries
    3. CULTURE: music, movies, TV shows, books, art
    4. SOCIETY: lifestyle trends, generational topics, relationships
    5. POLITICS/WORLD: current events, policy debates (be balanced)
    6. PHILOSOPHY/IDEAS: debates, ethical questions, thought experiments

    DO NOT return multiple topics about the same subject (e.g., no 3 AI ethics topics).
    Each topic should be from a DIFFERENT domain.

    AVOID: Celebrity gossip, sports scores, marketing/promotional content.

    FORMAT each topic as:
    N. **Title**: Brief description of why it's interesting for discussion

    Return exactly 10-12 topics. Diversity is REQUIRED - do not cluster on any single theme.
    """

    chat(prompt, tools: ["x_search"])
  end

  # Private functions

  defp build_request_body(prompt, tools) do
    base = %{
      "model" => config()[:model] || "grok-4-1-fast",
      "messages" => [
        %{"role" => "user", "content" => prompt}
      ]
    }

    if Enum.empty?(tools) do
      base
    else
      Map.put(base, "tools", build_tools(tools))
    end
  end

  # Build request body for the /responses endpoint (search tools)
  defp build_responses_body(prompt, tools) do
    base = %{
      "model" => config()[:model] || "grok-4-1-fast",
      "input" => [
        %{"role" => "user", "content" => prompt}
      ]
    }

    if Enum.empty?(tools) do
      base
    else
      Map.put(base, "tools", build_search_tools(tools))
    end
  end

  defp build_tools(tool_names) do
    Enum.map(tool_names, fn
      other -> %{"type" => other}
    end)
  end

  defp build_search_tools(tool_names) do
    Enum.map(tool_names, fn
      "web_search" ->
        %{"type" => "web_search"}

      "x_search" ->
        %{"type" => "x_search"}

      other ->
        %{"type" => other}
    end)
  end

  defp make_request(endpoint, body, timeout) do
    url = "#{config()[:base_url]}#{endpoint}"

    headers = [
      {"authorization", "Bearer #{config()[:api_key]}"},
      {"content-type", "application/json"}
    ]

    Req.post(url,
      json: body,
      headers: headers,
      receive_timeout: timeout
    )
  end

  defp parse_response(body) when is_binary(body) do
    Logger.info("Parsing binary response, length: #{byte_size(body)}")
    case Jason.decode(body) do
      {:ok, decoded} -> parse_response(decoded)
      {:error, err} ->
        Logger.error("Failed to decode JSON: #{inspect(err)}")
        {:error, :invalid_json}
    end
  end

  # Parse /chat/completions response
  defp parse_response(%{"choices" => [%{"message" => message} | _]} = response) do
    content = message["content"] || ""
    citations = response["citations"] || []
    Logger.info("Parsed chat/completions response, content length: #{String.length(content)}")

    {:ok,
     %{
       content: content,
       citations: citations,
       usage: response["usage"]
     }}
  end

  # Parse /responses endpoint response (search tools)
  defp parse_response(%{"output" => output} = response) when is_list(output) do
    # Find the assistant message in the output (last message with type: "message")
    content =
      output
      |> Enum.filter(fn item -> item["type"] == "message" end)
      |> List.last()
      |> case do
        %{"content" => content_list} when is_list(content_list) ->
          # Find the output_text item
          content_list
          |> Enum.find_value("", fn
            %{"type" => "output_text", "text" => text} -> text
            %{"type" => "text", "text" => text} -> text
            _ -> nil
          end)

        _ ->
          ""
      end

    citations = response["citations"] || []
    Logger.info("Parsed /responses response, content length: #{String.length(content)}")

    {:ok,
     %{
       content: content,
       citations: citations,
       usage: response["usage"]
     }}
  end

  defp parse_response(response) when is_map(response) do
    Logger.warning("Unexpected Grok response format, keys: #{inspect(Map.keys(response))}")
    Logger.info("Full response: #{inspect(response, limit: 3000)}")
    {:error, :unexpected_response_format}
  end

  defp parse_response(response) do
    Logger.warning("Unexpected Grok response type: #{inspect(response, limit: 500)}")
    {:error, :unexpected_response_format}
  end
end
