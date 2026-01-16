defmodule Gridroom.Grok.NodeGenerator do
  @moduledoc """
  Generates grid nodes from trending topics.

  Handles positioning to avoid overlaps and applies Lumon-style
  descriptions to system-generated content.
  """

  alias Gridroom.Grid
  alias Gridroom.Grok.{TrendFetcher, TrendRefiner}

  require Logger

  # Minimum distance between nodes to avoid visual overlap
  @min_node_distance 80

  # Grid bounds for trend node placement
  @trend_zone_min_x -400
  @trend_zone_max_x 400
  @trend_zone_min_y -300
  @trend_zone_max_y 300

  @doc """
  Fetch trends and create nodes for them.

  Returns `{:ok, created_nodes}` or `{:error, reason}`.

  Options:
  - `:max_nodes` - Maximum number of nodes to create (default: 3)
  - `:dry_run` - If true, returns what would be created without creating (default: false)
  """
  def generate_trend_nodes(opts \\ []) do
    max_nodes = Keyword.get(opts, :max_nodes, 3)
    dry_run = Keyword.get(opts, :dry_run, false)
    skip_refinement = Keyword.get(opts, :skip_refinement, false)

    with {:ok, trends} <- TrendFetcher.fetch_trends(),
         existing_nodes <- Grid.list_nodes(),
         existing_titles <- MapSet.new(existing_nodes, & &1.title) do
      # Filter out trends that already have nodes
      new_trends =
        trends
        |> Enum.reject(fn trend -> MapSet.member?(existing_titles, trend.title) end)
        |> Enum.take(max_nodes)

      # Second LLM pass: refine descriptions and generate source TLDRs
      refined_trends =
        if skip_refinement do
          new_trends
        else
          Logger.info("Refining #{length(new_trends)} trends with LLM...")
          TrendRefiner.refine_trends(new_trends)
        end

      if dry_run do
        {:ok, Enum.map(refined_trends, &build_node_attrs(&1, existing_nodes))}
      else
        created_nodes =
          refined_trends
          |> Enum.map(fn trend ->
            attrs = build_node_attrs(trend, existing_nodes)
            create_trend_node(attrs)
          end)
          |> Enum.filter(&match?({:ok, _}, &1))
          |> Enum.map(fn {:ok, node} -> node end)

        Logger.info("Generated #{length(created_nodes)} trend nodes")
        {:ok, created_nodes}
      end
    end
  end

  @doc """
  Build node attributes from a trend, finding a suitable position.
  """
  def build_node_attrs(trend, existing_nodes) do
    position = find_available_position(existing_nodes)

    %{
      title: trend.title,
      description: trend.description,
      position_x: position.x,
      position_y: position.y,
      node_type: infer_node_type(trend),
      glyph_shape: "hexagon",
      glyph_color: trend_color(),
      sources: trend[:sources] || []
    }
  end

  @doc """
  Find a position that doesn't overlap with existing nodes.
  Uses random placement within the trend zone with collision detection.
  """
  def find_available_position(existing_nodes, attempts \\ 0)

  def find_available_position(_existing_nodes, attempts) when attempts > 50 do
    # Give up and return a random position
    %{
      x: random_in_range(@trend_zone_min_x, @trend_zone_max_x),
      y: random_in_range(@trend_zone_min_y, @trend_zone_max_y)
    }
  end

  def find_available_position(existing_nodes, attempts) do
    candidate = %{
      x: random_in_range(@trend_zone_min_x, @trend_zone_max_x),
      y: random_in_range(@trend_zone_min_y, @trend_zone_max_y)
    }

    if position_available?(candidate, existing_nodes) do
      candidate
    else
      find_available_position(existing_nodes, attempts + 1)
    end
  end

  defp position_available?(candidate, existing_nodes) do
    Enum.all?(existing_nodes, fn node ->
      distance(candidate, %{x: node.position_x, y: node.position_y}) >= @min_node_distance
    end)
  end

  defp distance(p1, p2) do
    :math.sqrt(:math.pow(p1.x - p2.x, 2) + :math.pow(p1.y - p2.y, 2))
  end

  defp random_in_range(min, max) do
    min + :rand.uniform() * (max - min)
  end

  # Infer node type from trend content
  defp infer_node_type(%{title: title, description: description}) do
    text = String.downcase(title <> " " <> description)

    cond do
      String.contains?(text, ["?", "question", "why", "how", "what"]) -> "question"
      String.contains?(text, ["debate", "controversial", "vs", "versus"]) -> "debate"
      String.contains?(text, ["quiet", "meditation", "reflection"]) -> "quiet"
      true -> "discussion"
    end
  end

  # Subtle amber/gold color for system-generated trend nodes
  defp trend_color do
    colors = ["#b8956b", "#a68b5b", "#c9a066", "#9a8055"]
    Enum.random(colors)
  end

  defp create_trend_node(attrs) do
    case Grid.create_node(attrs) do
      {:ok, node} = success ->
        Logger.info("Created trend node: #{node.title}")
        success

      {:error, changeset} = error ->
        Logger.warning("Failed to create trend node: #{inspect(changeset.errors)}")
        error
    end
  end
end
