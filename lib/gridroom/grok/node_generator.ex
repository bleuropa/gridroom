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
  @min_node_distance 100

  # Placement parameters for golden angle spiral
  @base_radius 120
  @radius_increment 35
  @golden_angle 137.5077 * :math.pi() / 180  # ~2.399 radians

  @doc """
  Fetch trends and create nodes for them.

  Returns `{:ok, created_nodes}` or `{:error, reason}`.

  Options:
  - `:max_nodes` - Maximum number of nodes to create (default: 7)
  - `:dry_run` - If true, returns what would be created without creating (default: false)
  """
  def generate_trend_nodes(opts \\ []) do
    max_nodes = Keyword.get(opts, :max_nodes, 7)
    dry_run = Keyword.get(opts, :dry_run, false)
    skip_refinement = Keyword.get(opts, :skip_refinement, false)

    # Get existing nodes to pass to the LLM for context-aware deduplication
    existing_nodes = Grid.list_nodes()
    Logger.info("Found #{length(existing_nodes)} existing nodes")

    with {:ok, trends} <- TrendFetcher.fetch_trends(existing_nodes: existing_nodes) do
      # Take only the max_nodes we want (LLM already avoided duplicates)
      new_trends = Enum.take(trends, max_nodes)
      Logger.info("Creating #{length(new_trends)} new trend nodes")

      # Second LLM pass: refine descriptions and generate source TLDRs
      refined_trends =
        if skip_refinement do
          new_trends
        else
          Logger.info("Refining #{length(new_trends)} trends with LLM...")
          TrendRefiner.refine_trends(new_trends)
        end

      if dry_run do
        # For dry run, pre-calculate all positions accounting for each other
        {attrs_list, _} =
          Enum.map_reduce(refined_trends, existing_nodes, fn trend, nodes_so_far ->
            attrs = build_node_attrs(trend, nodes_so_far)
            # Create a pseudo-node for position tracking
            pseudo_node = %{position_x: attrs.position_x, position_y: attrs.position_y}
            {attrs, [pseudo_node | nodes_so_far]}
          end)
        {:ok, attrs_list}
      else
        # Create nodes one at a time, tracking positions as we go
        {created_nodes, _} =
          Enum.map_reduce(refined_trends, existing_nodes, fn trend, nodes_so_far ->
            attrs = build_node_attrs(trend, nodes_so_far)
            result = create_trend_node(attrs)

            case result do
              {:ok, node} ->
                # Add new node to tracking list for next position calculation
                {node, [node | nodes_so_far]}

              {:error, _} ->
                {nil, nodes_so_far}
            end
          end)

        created_nodes = Enum.reject(created_nodes, &is_nil/1)
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
  Find a position using golden angle spiral placement.
  Creates a natural, aesthetically pleasing distribution around the grid center.
  """
  def find_available_position(existing_nodes, _attempts \\ 0) do
    # Start from after the existing nodes on the spiral
    start_index = length(existing_nodes)

    # Try positions along the golden angle spiral until we find one that doesn't overlap
    find_spiral_position(existing_nodes, start_index, 0)
  end

  defp find_spiral_position(_existing_nodes, index, retries) when retries > 20 do
    # Fallback: add some randomness to break out of collisions
    base_pos = calculate_spiral_position(index + retries)
    jitter = 30 + retries * 10
    %{
      x: base_pos.x + (:rand.uniform() - 0.5) * jitter,
      y: base_pos.y + (:rand.uniform() - 0.5) * jitter
    }
  end

  defp find_spiral_position(existing_nodes, index, retries) do
    candidate = calculate_spiral_position(index + retries)

    if position_available?(candidate, existing_nodes) do
      candidate
    else
      find_spiral_position(existing_nodes, index, retries + 1)
    end
  end

  defp calculate_spiral_position(index) do
    # Golden angle spiral: r = a + b*n, theta = n * golden_angle
    # This creates a sunflower-like distribution
    n = index + 1  # 1-indexed for nicer math
    radius = @base_radius + @radius_increment * :math.sqrt(n)
    angle = n * @golden_angle

    # Add slight randomness to avoid perfect regularity
    radius_jitter = radius * 0.1 * (:rand.uniform() - 0.5)
    angle_jitter = 0.1 * (:rand.uniform() - 0.5)

    %{
      x: (radius + radius_jitter) * :math.cos(angle + angle_jitter),
      y: (radius + radius_jitter) * :math.sin(angle + angle_jitter)
    }
  end

  defp position_available?(candidate, existing_nodes) do
    Enum.all?(existing_nodes, fn node ->
      distance(candidate, %{x: node.position_x, y: node.position_y}) >= @min_node_distance
    end)
  end

  defp distance(p1, p2) do
    :math.sqrt(:math.pow(p1.x - p2.x, 2) + :math.pow(p1.y - p2.y, 2))
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
