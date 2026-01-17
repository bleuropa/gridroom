defmodule Gridroom.Grok.FolderFetcher do
  @moduledoc """
  Fetches trending topics for a specific folder using Grok API.
  Each folder has its own system prompt that guides topic selection.
  """

  alias Gridroom.Grok.Client
  alias Gridroom.Folders.Folder

  require Logger

  @doc """
  Fetch topics for a folder using its custom system prompt.

  Options:
  - `:existing_nodes` - List of existing node maps to avoid duplicates

  Returns a list of trend maps with :title, :description, and :sources keys.
  """
  def fetch_folder_trends(%Folder{} = folder, opts \\ []) do
    existing_nodes = Keyword.get(opts, :existing_nodes, [])

    existing_context =
      if Enum.empty?(existing_nodes) do
        ""
      else
        nodes_list =
          existing_nodes
          |> Enum.take(30)
          |> Enum.map(fn node -> "- #{node.title}" end)
          |> Enum.join("\n")

        """

        EXISTING TOPICS TO AVOID (do not suggest similar topics):
        #{nodes_list}

        """
      end

    prompt = folder.system_prompt <> existing_context

    case Client.chat(prompt, tools: ["x_search"]) do
      {:ok, %{content: content}} ->
        trends = parse_trends(content)
        Logger.info("Parsed #{length(trends)} trends for folder #{folder.name}")
        {:ok, trends}

      {:error, reason} ->
        Logger.error("Failed to fetch trends for folder #{folder.name}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Parse the Grok response content into structured trends.
  Same parsing logic as TrendFetcher but kept separate for clarity.
  """
  def parse_trends(content) when is_binary(content) do
    # Split by numbered items (1. 2. 3. etc) to handle multi-line entries
    blocks = String.split(content, ~r/\n(?=\d+\.\s)/)

    blocks
    |> Enum.map(&parse_trend_block/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.take(9)
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
    |> Enum.take(3)
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

  # Add a subtle Lumon/mysterious tone to descriptions
  defp lumonify(text) do
    text
    |> String.replace(~r/everyone is talking about/i, "many are contemplating")
    |> String.replace(~r/going viral/i, "gaining resonance")
    |> String.replace(~r/hot topic/i, "matter of consideration")
    |> String.replace(~r/breaking news/i, "developing situation")
  end

  defp truncate(text, max_length) do
    if String.length(text) > max_length do
      String.slice(text, 0, max_length - 1) <> "..."
    else
      text
    end
  end
end
