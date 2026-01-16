defmodule Gridroom.Grok.TrendRefiner do
  @moduledoc """
  Second-pass LLM refinement for trend nodes.

  Takes raw trend data and generates:
  - Lumon-style node descriptions
  - TLDR summaries for each source
  """

  alias Gridroom.Grok.Client

  require Logger

  @doc """
  Refine a list of trends with LLM-generated descriptions and source summaries.

  Takes raw trends from TrendFetcher and returns enhanced versions.
  """
  def refine_trends(trends) when is_list(trends) do
    trends
    |> Enum.map(&refine_trend/1)
  end

  @doc """
  Refine a single trend with better description and source TLDRs.
  """
  def refine_trend(trend) do
    prompt = build_refinement_prompt(trend)

    case Client.chat(prompt, tools: []) do
      {:ok, %{content: content}} ->
        parse_refined_trend(content, trend)

      {:error, reason} ->
        Logger.warning("Failed to refine trend '#{trend.title}': #{inspect(reason)}")
        # Return original trend with default refinements
        fallback_refinement(trend)
    end
  end

  defp build_refinement_prompt(trend) do
    source_list =
      (trend[:sources] || [])
      |> Enum.with_index(1)
      |> Enum.map(fn {source, idx} -> "#{idx}. #{source["url"]}" end)
      |> Enum.join("\n")

    """
    You are crafting content for Gridroom, a mysterious social platform with a Severance/Lumon aesthetic.
    The tone should be: understated, slightly cryptic, corporate-philosophical, inviting contemplation.

    Given this trending topic:
    TITLE: #{trend.title}
    RAW DESCRIPTION: #{trend.description}

    SOURCES:
    #{source_list}

    Generate:

    1. DESCRIPTION: A 1-2 sentence Lumon-style description for this conversation node.
       - Avoid hype words (viral, hot, breaking)
       - Use contemplative language (consider, reflect, examine, observe)
       - Hint at depth without revealing everything
       - Make it feel like an invitation to think

    2. SOURCE_SUMMARIES: For each source URL, provide a brief TLDR (max 15 words) of what that source discusses.
       Format as: [1] Summary here | [2] Summary here | [3] Summary here

    Respond in this exact format:
    DESCRIPTION: <your description>
    SOURCE_SUMMARIES: <summaries separated by |>
    """
  end

  defp parse_refined_trend(content, original_trend) do
    description = extract_field(content, "DESCRIPTION") || original_trend.description
    summaries_raw = extract_field(content, "SOURCE_SUMMARIES") || ""

    # Parse summaries and attach to sources
    summaries = parse_summaries(summaries_raw)
    sources = attach_summaries_to_sources(original_trend[:sources] || [], summaries)

    %{
      title: original_trend.title,
      description: lumonify_description(description),
      sources: sources
    }
  end

  defp extract_field(content, field_name) do
    case Regex.run(~r/#{field_name}:\s*(.+?)(?=\n[A-Z_]+:|$)/s, content) do
      [_, value] -> String.trim(value)
      _ -> nil
    end
  end

  defp parse_summaries(raw) do
    raw
    |> String.split("|")
    |> Enum.map(&String.trim/1)
    |> Enum.map(fn summary ->
      # Remove [N] prefix if present
      String.replace(summary, ~r/^\[\d+\]\s*/, "")
    end)
  end

  defp attach_summaries_to_sources(sources, summaries) do
    sources
    |> Enum.with_index()
    |> Enum.map(fn {source, idx} ->
      summary = Enum.at(summaries, idx, "")
      Map.put(source, "summary", summary)
    end)
  end

  defp fallback_refinement(trend) do
    %{
      title: trend.title,
      description: lumonify_description(trend.description),
      sources: Enum.map(trend[:sources] || [], fn source ->
        Map.put(source, "summary", "")
      end)
    }
  end

  # Additional Lumonification for descriptions
  defp lumonify_description(text) do
    text
    |> String.replace(~r/everyone is talking about/i, "many are contemplating")
    |> String.replace(~r/going viral/i, "gaining resonance across the grid")
    |> String.replace(~r/hot topic/i, "matter of consideration")
    |> String.replace(~r/breaking news/i, "developing situation")
    |> String.replace(~r/trending/i, "emerging")
    |> String.replace(~r/buzz/i, "attention")
    |> String.replace(~r/exploding/i, "expanding")
    |> String.replace(~r/internet is/i, "the collective is")
    |> truncate(250)
  end

  defp truncate(text, max) do
    if String.length(text) > max do
      String.slice(text, 0, max - 1) <> "…"
    else
      text
    end
  end
end
