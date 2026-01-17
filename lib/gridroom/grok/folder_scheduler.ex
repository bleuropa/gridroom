defmodule Gridroom.Grok.FolderScheduler do
  @moduledoc """
  GenServer that periodically fetches topics for each folder.

  Runs daily at a configured time (default: 6 AM UTC) to populate
  each folder with fresh topics from X search.

  Controlled by the `:grok` config:
  - `enabled: true/false` - Whether to run the scheduler
  - `folder_schedule_hour` - Hour (UTC) to run daily (default: 6)
  """

  use GenServer

  alias Gridroom.Grok.{Client, FolderFetcher, TrendRefiner}
  alias Gridroom.{Folders, Grid}
  alias Gridroom.Folders.Folder

  require Logger

  # Public API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Manually trigger topic fetching for all folders.
  """
  def trigger_all_folders do
    GenServer.cast(__MODULE__, :trigger_all_folders)
  end

  @doc """
  Manually trigger topic fetching for a specific folder.
  """
  def trigger_folder(folder_slug) when is_binary(folder_slug) do
    GenServer.cast(__MODULE__, {:trigger_folder, folder_slug})
  end

  def trigger_folder(%Folder{} = folder) do
    GenServer.cast(__MODULE__, {:trigger_folder, folder})
  end

  @doc """
  Get the current scheduler status.
  """
  def status do
    GenServer.call(__MODULE__, :status)
  end

  # GenServer callbacks

  @impl true
  def init(_opts) do
    state = %{
      last_run: nil,
      last_results: %{},
      total_runs: 0
    }

    if Client.enabled?() do
      schedule_next_daily_run()
      Logger.info("Folder scheduler started - will run daily")
    else
      Logger.info("Folder scheduler disabled (Grok API disabled)")
    end

    {:ok, state}
  end

  @impl true
  def handle_cast(:trigger_all_folders, state) do
    Logger.info("Folder scheduler: triggering all folders manually")
    new_state = fetch_all_folders(state)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:trigger_folder, folder_slug}, state) when is_binary(folder_slug) do
    case Folders.get_folder_by_slug(folder_slug) do
      nil ->
        Logger.warning("Folder not found: #{folder_slug}")
        {:noreply, state}

      folder ->
        Logger.info("Folder scheduler: triggering folder #{folder.name} manually")
        result = fetch_folder_topics(folder)
        new_results = Map.put(state.last_results, folder.slug, result)
        {:noreply, %{state | last_results: new_results}}
    end
  end

  @impl true
  def handle_cast({:trigger_folder, %Folder{} = folder}, state) do
    Logger.info("Folder scheduler: triggering folder #{folder.name} manually")
    result = fetch_folder_topics(folder)
    new_results = Map.put(state.last_results, folder.slug, result)
    {:noreply, %{state | last_results: new_results}}
  end

  @impl true
  def handle_call(:status, _from, state) do
    status = %{
      enabled: Client.enabled?(),
      last_run: state.last_run,
      last_results: state.last_results,
      total_runs: state.total_runs,
      folders: Enum.map(Folders.list_active_folders(), & &1.name)
    }

    {:reply, status, state}
  end

  @impl true
  def handle_info(:scheduled_daily_run, state) do
    new_state =
      if Client.enabled?() do
        Logger.info("Running scheduled daily folder topic fetch...")
        fetch_all_folders(state)
      else
        state
      end

    schedule_next_daily_run()
    {:noreply, new_state}
  end

  # Private functions

  defp fetch_all_folders(state) do
    folders = Folders.list_active_folders()
    Logger.info("Fetching topics for #{length(folders)} folders")

    results =
      Enum.reduce(folders, %{}, fn folder, acc ->
        # Add delay between folders to avoid rate limiting
        if map_size(acc) > 0, do: Process.sleep(2000)

        result = fetch_folder_topics(folder)
        Map.put(acc, folder.slug, result)
      end)

    %{
      state
      | last_run: DateTime.utc_now(),
        last_results: results,
        total_runs: state.total_runs + 1
    }
  end

  defp fetch_folder_topics(%Folder{} = folder) do
    today = Date.utc_today()

    # Get existing nodes in this folder to avoid duplicates
    existing_nodes = Folders.list_folder_nodes(folder.id, today)

    case FolderFetcher.fetch_folder_trends(folder, existing_nodes: existing_nodes) do
      {:ok, trends} ->
        # Refine trends with second LLM pass
        refined_trends = TrendRefiner.refine_trends(trends)

        # Create nodes for each trend
        created_nodes =
          Enum.map(refined_trends, fn trend ->
            create_folder_node(trend, folder, today)
          end)
          |> Enum.reject(&is_nil/1)

        Logger.info("Created #{length(created_nodes)} nodes for folder #{folder.name}")
        {:ok, length(created_nodes)}

      {:error, reason} ->
        Logger.error("Failed to fetch topics for folder #{folder.name}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp create_folder_node(trend, folder, date) do
    # Use golden angle spiral for positioning within folder's nodes
    existing_nodes = Folders.list_folder_nodes(folder.id, date)
    position = find_folder_position(existing_nodes)

    attrs = %{
      title: trend.title,
      description: trend.description,
      position_x: position.x,
      position_y: position.y,
      node_type: infer_node_type(trend),
      glyph_shape: "hexagon",
      glyph_color: folder_color(folder.slug),
      sources: trend[:sources] || [],
      folder_id: folder.id,
      folder_date: date
    }

    case Grid.create_node(attrs) do
      {:ok, node} ->
        Logger.info("Created node '#{node.title}' for folder #{folder.name}")
        node

      {:error, changeset} ->
        Logger.warning("Failed to create node: #{inspect(changeset.errors)}")
        nil
    end
  end

  # Position calculation for folder nodes
  @base_radius 100
  @radius_increment 40
  @golden_angle 137.5077 * :math.pi() / 180

  defp find_folder_position(existing_nodes) do
    index = length(existing_nodes)
    n = index + 1
    radius = @base_radius + @radius_increment * :math.sqrt(n)
    angle = n * @golden_angle

    # Add slight randomness
    radius_jitter = radius * 0.1 * (:rand.uniform() - 0.5)
    angle_jitter = 0.1 * (:rand.uniform() - 0.5)

    %{
      x: (radius + radius_jitter) * :math.cos(angle + angle_jitter),
      y: (radius + radius_jitter) * :math.sin(angle + angle_jitter)
    }
  end

  # Infer node type from trend content
  defp infer_node_type(%{title: title, description: description}) do
    text = String.downcase(title <> " " <> (description || ""))

    cond do
      String.contains?(text, ["?", "question", "why", "how", "what"]) -> "question"
      String.contains?(text, ["debate", "controversial", "vs", "versus"]) -> "debate"
      String.contains?(text, ["quiet", "meditation", "reflection"]) -> "quiet"
      true -> "discussion"
    end
  end

  # Different colors per folder for visual distinction
  defp folder_color("sports"), do: "#7a9a6d"   # Green
  defp folder_color("gossip"), do: "#c9a066"   # Gold
  defp folder_color("tech"), do: "#6d8a9a"     # Blue-gray
  defp folder_color("politics"), do: "#9a6d7a" # Mauve
  defp folder_color("finance"), do: "#8a9a6d"  # Olive
  defp folder_color("science"), do: "#6d7a9a"  # Blue
  defp folder_color(_), do: "#8a7d6d"          # Default brown

  # Schedule next run at configured hour UTC
  defp schedule_next_daily_run do
    config = Application.get_env(:gridroom, :grok, [])
    schedule_hour = Keyword.get(config, :folder_schedule_hour, 6)

    now = DateTime.utc_now()
    today_at_hour = %{now | hour: schedule_hour, minute: 0, second: 0, microsecond: {0, 0}}

    next_run =
      if DateTime.compare(now, today_at_hour) == :lt do
        today_at_hour
      else
        DateTime.add(today_at_hour, 1, :day)
      end

    delay_ms = DateTime.diff(next_run, now, :millisecond)
    Logger.info("Next folder fetch scheduled for #{next_run} (in #{div(delay_ms, 3600000)}h)")

    Process.send_after(self(), :scheduled_daily_run, delay_ms)
  end
end
