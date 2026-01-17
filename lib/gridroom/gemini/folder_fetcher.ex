defmodule Gridroom.Gemini.FolderFetcher do
  @moduledoc """
  Fetches trending topics for a specific folder using Gemini API with Google Search grounding.
  Each folder has its own system prompt that guides topic selection.
  """

  alias Gridroom.Gemini.Client
  alias Gridroom.Folders.Folder

  require Logger

  @doc """
  Fetch topics for a folder using Gemini with Google Search grounding.

  Options:
  - `:existing_nodes` - List of existing node maps to avoid duplicates
  - `:count` - Number of topics to fetch (default: 4)

  Returns a list of trend maps with :title, :description, :sources, and :source_api keys.
  """
  def fetch_folder_trends(%Folder{} = folder, opts \\ []) do
    existing_nodes = Keyword.get(opts, :existing_nodes, [])
    count = Keyword.get(opts, :count, 4)

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

    prompt = build_gemini_prompt(folder, existing_context, count)

    case Client.generate(prompt, grounding: true) do
      {:ok, %{content: content, grounding_chunks: chunks}} ->
        trends = parse_trends(content, chunks)
        Logger.info("Gemini: Parsed #{length(trends)} trends for folder #{folder.name}")
        {:ok, trends}

      {:error, reason} ->
        Logger.error("Gemini: Failed to fetch trends for folder #{folder.name}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Build a Gemini-specific prompt that leverages Google Search grounding
  defp build_gemini_prompt(folder, existing_context, count) do
    """
    You are a topic curator for the "#{folder.name}" category.

    #{folder.system_prompt}
    #{existing_context}

    Using Google Search to find the most current and relevant topics, return exactly #{count} discussion topics.

    FORMAT your response as a numbered list:
    1. **Topic Title**: Brief description of why this is interesting for discussion
    2. **Topic Title**: Brief description
    ...

    Requirements:
    - Each topic must be currently trending or newsworthy (use real-time search)
    - Topics should be conversation starters, not just news headlines
    - Descriptions should hint at debate potential or multiple perspectives
    - Keep titles concise (under 50 characters)
    - Keep descriptions under 200 characters
    """
  end

  @doc """
  Parse the Gemini response content into structured trends.
  Incorporates grounding chunks as source citations.
  """
  def parse_trends(content, grounding_chunks) when is_binary(content) do
    # Split by numbered items (1. 2. 3. etc)
    blocks = String.split(content, ~r/\n(?=\d+\.\s)/)

    blocks
    |> Enum.map(fn block -> parse_trend_block(block, grounding_chunks) end)
    |> Enum.reject(&is_nil/1)
    |> Enum.take(4)
  end

  def parse_trends(_, _), do: []

  defp parse_trend_block(block, grounding_chunks) do
    block = String.trim(block)

    cond do
      # Pattern: "1. **Title**: Description" or "1. **Title** - Description"
      Regex.match?(~r/^[\d]+\.\s*\*\*(.+?)\*\*\s*[-–:]?\s*(.+)$/su, block) ->
        case Regex.run(~r/^[\d]+\.\s*\*\*(.+?)\*\*\s*[-–:]?\s*(.+)$/su, block) do
          [_, title, description] ->
            build_trend(title, description, grounding_chunks)

          _ ->
            nil
        end

      # Pattern: "1. Title: Description" or "1. Title - Description"
      Regex.match?(~r/^[\d]+\.\s*(.+?)\s*[-–:]\s*(.+)$/su, block) ->
        case Regex.run(~r/^[\d]+\.\s*(.+?)\s*[-–:]\s*(.+)$/su, block) do
          [_, title, description] when byte_size(title) > 3 ->
            build_trend(title, description, grounding_chunks)

          _ ->
            nil
        end

      true ->
        nil
    end
  end

  defp build_trend(title, description, grounding_chunks) do
    # Convert grounding chunks to source format
    sources =
      grounding_chunks
      |> Enum.take(3)
      |> Enum.map(fn chunk ->
        %{
          "url" => chunk.uri,
          "title" => chunk.title,
          "type" => "google"
        }
      end)

    %{
      title: clean_title(title),
      description: clean_description(description),
      sources: sources,
      source_api: "gemini"
    }
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
