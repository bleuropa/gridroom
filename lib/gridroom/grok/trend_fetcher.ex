defmodule Gridroom.Grok.TrendFetcher do
  @moduledoc """
  Fetches trending topics from Grok API and parses them into structured data.
  """

  alias Gridroom.Grok.Client

  require Logger

  @doc """
  Fetch and parse trending topics.

  Returns a list of trend maps with :title, :description, and :sources keys.
  """
  def fetch_trends do
    case Client.fetch_trends() do
      {:ok, %{content: content}} ->
        trends = parse_trends(content)
        Logger.info("Parsed #{length(trends)} trends from Grok response")
        {:ok, trends}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Parse the Grok response content into structured trends.

  Expects content in a format like:
  1. **Topic Title**: Description [[1]](url)[[2]](url)
  2. **Another Topic**: Another description [[3]](url)
  """
  def parse_trends(content) when is_binary(content) do
    Logger.info("Parsing trends from content (#{String.length(content)} chars)")

    # Split by numbered items (1. 2. 3. etc) to handle multi-line entries
    blocks = String.split(content, ~r/\n(?=\d+\.\s)/)
    Logger.info("Split into #{length(blocks)} blocks")

    parsed =
      blocks
      |> Enum.map(&parse_trend_block/1)
      |> Enum.reject(&is_nil/1)

    Logger.info("Successfully parsed #{length(parsed)} trends from #{length(blocks)} blocks")

    parsed |> Enum.take(12)
  end

  def parse_trends(_), do: []

  defp parse_trend_block(block) do
    block = String.trim(block)

    # Extract all X URLs from the block
    sources = extract_sources(block)

    # Remove citation markers for cleaner parsing
    clean_block = String.replace(block, ~r/\[\[\d+\]\]\([^)]+\)/, "")

    cond do
      # Pattern: "1. **Title**: Description" or "1. **Title** - Description"
      Regex.match?(~r/^[\d]+\.\s*\*\*(.+?)\*\*\s*[-–:]?\s*(.+)$/su, clean_block) ->
        case Regex.run(~r/^[\d]+\.\s*\*\*(.+?)\*\*\s*[-–:]?\s*(.+)$/su, clean_block) do
          [_, title, description] ->
            %{
              title: clean_title(title),
              description: clean_description(description),
              sources: sources
            }

          _ ->
            nil
        end

      # Pattern: "1. Title: Description" or "1. Title - Description"
      Regex.match?(~r/^[\d]+\.\s*(.+?)\s*[-–:]\s*(.+)$/su, clean_block) ->
        case Regex.run(~r/^[\d]+\.\s*(.+?)\s*[-–:]\s*(.+)$/su, clean_block) do
          [_, title, description] when byte_size(title) > 3 ->
            %{
              title: clean_title(title),
              description: clean_description(description),
              sources: sources
            }

          _ ->
            nil
        end

      true ->
        nil
    end
  end

  defp extract_sources(text) do
    # Match [[N]](url) patterns and extract URLs
    ~r/\[\[\d+\]\]\((https?:\/\/[^)]+)\)/
    |> Regex.scan(text)
    |> Enum.map(fn [_, url] ->
      %{
        "url" => url,
        "type" => source_type(url)
      }
    end)
    |> Enum.uniq_by(& &1["url"])
    |> Enum.take(3)  # Limit to 3 sources per trend
  end

  defp source_type(url) do
    cond do
      String.contains?(url, "x.com") or String.contains?(url, "twitter.com") -> "x"
      true -> "web"
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
