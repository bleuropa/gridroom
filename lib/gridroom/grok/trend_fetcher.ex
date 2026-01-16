defmodule Gridroom.Grok.TrendFetcher do
  @moduledoc """
  Fetches trending topics from Grok API and parses them into structured data.
  """

  alias Gridroom.Grok.Client

  require Logger

  @doc """
  Fetch and parse trending topics.

  Returns a list of trend maps with :title and :description keys.
  """
  def fetch_trends do
    case Client.fetch_trends() do
      {:ok, %{content: content}} ->
        trends = parse_trends(content)
        {:ok, trends}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Parse the Grok response content into structured trends.

  Expects content in a format like:
  1. **Topic Title** - Description of why it's interesting
  2. **Another Topic** - Another description
  """
  def parse_trends(content) when is_binary(content) do
    content
    |> String.split("\n")
    |> Enum.map(&parse_trend_line/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.take(7)
  end

  def parse_trends(_), do: []

  defp parse_trend_line(line) do
    line = String.trim(line)

    cond do
      # Pattern: "1. **Title** - Description" or "- **Title** - Description"
      Regex.match?(~r/^[\d\-\*\.]+\s*\*\*(.+?)\*\*\s*[-–:]\s*(.+)$/u, line) ->
        case Regex.run(~r/^[\d\-\*\.]+\s*\*\*(.+?)\*\*\s*[-–:]\s*(.+)$/u, line) do
          [_, title, description] ->
            %{
              title: clean_title(title),
              description: clean_description(description)
            }

          _ ->
            nil
        end

      # Pattern: "1. Title - Description" or "- Title: Description"
      Regex.match?(~r/^[\d\-\*\.]+\s*(.+?)\s*[-–:]\s*(.+)$/u, line) ->
        case Regex.run(~r/^[\d\-\*\.]+\s*(.+?)\s*[-–:]\s*(.+)$/u, line) do
          [_, title, description] when byte_size(title) > 3 ->
            %{
              title: clean_title(title),
              description: clean_description(description)
            }

          _ ->
            nil
        end

      # Pattern: Just a title with no description (numbered list)
      Regex.match?(~r/^[\d]+\.\s*\*?\*?(.+?)\*?\*?\s*$/u, line) ->
        case Regex.run(~r/^[\d]+\.\s*\*?\*?(.+?)\*?\*?\s*$/u, line) do
          [_, title] when byte_size(title) > 3 ->
            %{
              title: clean_title(title),
              description: generate_placeholder_description(title)
            }

          _ ->
            nil
        end

      true ->
        nil
    end
  end

  defp clean_title(title) do
    title
    |> String.trim()
    |> String.replace(~r/^\*+|\*+$/, "")
    |> String.trim()
    |> truncate(50)
  end

  defp clean_description(description) do
    description
    |> String.trim()
    |> String.replace(~r/^\*+|\*+$/, "")
    |> String.trim()
    |> lumonify()
    |> truncate(200)
  end

  defp generate_placeholder_description(title) do
    "A conversation about #{String.downcase(title)}. Join the discussion."
  end

  # Add a subtle Lumon/mysterious tone to descriptions
  defp lumonify(text) do
    # Keep descriptions fairly neutral but slightly mysterious
    text
    |> String.replace(~r/everyone is talking about/i, "many are contemplating")
    |> String.replace(~r/going viral/i, "gaining resonance")
    |> String.replace(~r/hot topic/i, "matter of consideration")
    |> String.replace(~r/breaking news/i, "developing situation")
  end

  defp truncate(text, max_length) do
    if String.length(text) > max_length do
      String.slice(text, 0, max_length - 1) <> "…"
    else
      text
    end
  end
end
