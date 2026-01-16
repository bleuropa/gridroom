defmodule Gridroom.Grok.Client do
  @moduledoc """
  HTTP client for the xAI Grok API.

  Uses the chat completions endpoint with tools for search functionality.
  """

  require Logger

  @default_timeout 30_000

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
    unless enabled?() do
      {:error, :grok_disabled}
    else
      tools = Keyword.get(opts, :tools, [])
      timeout = Keyword.get(opts, :timeout, @default_timeout)

      body = build_request_body(prompt, tools)

      case make_request(body, timeout) do
        {:ok, %{status: 200, body: body}} ->
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

  @doc """
  Fetch trending topics using X search.
  """
  def fetch_trends do
    prompt = """
    What are the most interesting and conversation-worthy topics trending on X right now?
    Focus on topics that would spark thoughtful discussion - technology, culture, ideas, events.
    Avoid celebrity gossip, sports scores, or purely promotional content.
    List 5-7 topics with a brief description of why each is interesting.
    """

    chat(prompt, tools: ["x_search"])
  end

  # Private functions

  defp build_request_body(prompt, tools) do
    base = %{
      "model" => config()[:model] || "grok-3-fast-latest",
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

  defp build_tools(tool_names) do
    Enum.map(tool_names, fn
      "web_search" ->
        %{"type" => "web_search"}

      "x_search" ->
        %{"type" => "x_search"}

      other ->
        %{"type" => other}
    end)
  end

  defp make_request(body, timeout) do
    url = "#{config()[:base_url]}/chat/completions"

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
    case Jason.decode(body) do
      {:ok, decoded} -> parse_response(decoded)
      {:error, _} -> {:error, :invalid_json}
    end
  end

  defp parse_response(%{"choices" => [%{"message" => message} | _]} = response) do
    content = message["content"] || ""
    citations = response["citations"] || []

    {:ok,
     %{
       content: content,
       citations: citations,
       usage: response["usage"]
     }}
  end

  defp parse_response(response) do
    Logger.warning("Unexpected Grok response format: #{inspect(response)}")
    {:error, :unexpected_response_format}
  end
end
