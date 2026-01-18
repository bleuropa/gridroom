defmodule Gridroom.Folders do
  @moduledoc """
  The Folders context - manages MDR-style category folders for discussions.

  Folders organize discussions into categorical bins that users can refine through.
  Each folder has its own Oban job for daily topic fetching and tracks per-user
  completion progress.
  """

  import Ecto.Query
  alias Gridroom.Repo
  alias Gridroom.Folders.{Folder, UserFolderProgress, CommunityNodeSelection}
  alias Gridroom.Grid.{Node, Message}

  # Refresh interval for community folders (8 hours in seconds)
  @community_refresh_interval_seconds 8 * 60 * 60

  # Folder queries

  @doc """
  Lists all active folders in sort order.
  """
  def list_active_folders do
    Folder
    |> where([f], f.active == true)
    |> order_by([f], f.sort_order)
    |> Repo.all()
  end

  @doc """
  Gets a folder by slug.
  """
  def get_folder_by_slug(slug) do
    Repo.get_by(Folder, slug: slug)
  end

  @doc """
  Gets a folder by ID.
  """
  def get_folder(id), do: Repo.get(Folder, id)

  @doc """
  Creates a new folder.
  """
  def create_folder(attrs) do
    %Folder{}
    |> Folder.changeset(attrs)
    |> Repo.insert()
  end

  # Node-folder relationships

  @doc """
  Lists nodes for a folder on a specific date.
  For community folders, returns the curated selection instead.
  Optionally excludes nodes created by a specific user (for Peer Contributions).
  """
  def list_folder_nodes(folder_id, date, opts \\ []) do
    folder = get_folder(folder_id)
    exclude_creator_id = Keyword.get(opts, :exclude_creator_id)
    list_folder_nodes(folder, folder_id, date, exclude_creator_id)
  end

  defp list_folder_nodes(%Folder{is_community: true} = folder, _folder_id, _date, exclude_creator_id) do
    list_community_folder_nodes(folder, exclude_creator_id)
  end

  defp list_folder_nodes(_folder, folder_id, date, _exclude_creator_id) do
    Node
    |> where([n], n.folder_id == ^folder_id and n.folder_date == ^date)
    |> Repo.all()
    |> Repo.preload(:created_by)
  end

  @doc """
  Lists nodes for a folder on today's date.
  """
  def list_todays_folder_nodes(folder_id) do
    list_folder_nodes(folder_id, Date.utc_today())
  end

  @doc """
  Counts nodes in a folder for a specific date.
  For community folders, counts the curated selection instead.
  """
  def count_folder_nodes(folder_id, date) do
    folder = get_folder(folder_id)
    count_folder_nodes(folder, folder_id, date)
  end

  defp count_folder_nodes(%Folder{is_community: true} = folder, _folder_id, _date) do
    # For community folders, ensure selections are refreshed then count
    if needs_community_refresh?(folder) do
      refresh_community_selections(folder)
    end

    count_community_folder_nodes(folder)
  end

  defp count_folder_nodes(_folder, folder_id, date) do
    Node
    |> where([n], n.folder_id == ^folder_id and n.folder_date == ^date)
    |> Repo.aggregate(:count, :id)
  end

  # User progress tracking

  @doc """
  Gets or creates a user's progress record for a folder on a date.
  """
  def get_or_create_progress(user_id, folder_id, date \\ Date.utc_today()) do
    case Repo.get_by(UserFolderProgress, user_id: user_id, folder_id: folder_id, date: date) do
      nil ->
        total = count_folder_nodes(folder_id, date)

        %UserFolderProgress{}
        |> UserFolderProgress.changeset(%{
          user_id: user_id,
          folder_id: folder_id,
          date: date,
          total_count: total,
          refined_count: 0
        })
        |> Repo.insert()

      progress ->
        {:ok, progress}
    end
  end

  @doc """
  Increments the refined count for a user's folder progress.
  Returns {:ok, progress} or {:completed, progress} if folder is now complete.
  """
  def increment_progress(user_id, folder_id, date \\ Date.utc_today()) do
    {:ok, progress} = get_or_create_progress(user_id, folder_id, date)

    new_count = progress.refined_count + 1
    completed? = new_count >= progress.total_count

    attrs =
      if completed? do
        %{refined_count: new_count, completed_at: DateTime.utc_now() |> DateTime.truncate(:second)}
      else
        %{refined_count: new_count}
      end

    case progress
         |> UserFolderProgress.changeset(attrs)
         |> Repo.update() do
      {:ok, updated} ->
        if completed?, do: {:completed, updated}, else: {:ok, updated}

      error ->
        error
    end
  end

  @doc """
  Gets user's progress for all folders on a date.
  Returns a map of folder_id => progress record.
  """
  def get_user_progress_for_date(user_id, date \\ Date.utc_today()) do
    UserFolderProgress
    |> where([p], p.user_id == ^user_id and p.date == ^date)
    |> Repo.all()
    |> Map.new(fn p -> {p.folder_id, p} end)
  end

  @doc """
  Gets folders with user's progress for today.
  Returns list of {folder, progress} tuples where progress may be nil.
  """
  def list_folders_with_progress(user_id, date \\ Date.utc_today()) do
    folders = list_active_folders()
    progress_map = get_user_progress_for_date(user_id, date)

    Enum.map(folders, fn folder ->
      progress = Map.get(progress_map, folder.id)

      # Calculate total if no progress yet
      total =
        if progress do
          progress.total_count
        else
          count_folder_nodes(folder.id, date)
        end

      refined = if progress, do: progress.refined_count, else: 0
      completed? = progress != nil and progress.completed_at != nil

      %{
        folder: folder,
        progress: progress,
        total: total,
        refined: refined,
        completed: completed?
      }
    end)
  end

  @doc """
  Checks if a user has completed a folder for a date.
  """
  def folder_completed?(user_id, folder_id, date \\ Date.utc_today()) do
    UserFolderProgress
    |> where([p], p.user_id == ^user_id and p.folder_id == ^folder_id and p.date == ^date)
    |> where([p], not is_nil(p.completed_at))
    |> Repo.exists?()
  end

  @doc """
  Checks if all folders are completed for a user on a date.
  """
  def all_folders_completed?(user_id, date \\ Date.utc_today()) do
    folder_count =
      Folder
      |> where([f], f.active == true)
      |> Repo.aggregate(:count, :id)

    completed_count =
      UserFolderProgress
      |> where([p], p.user_id == ^user_id and p.date == ^date and not is_nil(p.completed_at))
      |> Repo.aggregate(:count, :id)

    folder_count > 0 and folder_count == completed_count
  end

  # Community Folder Support

  @doc """
  Lists nodes for a community folder.
  Handles refresh automatically if selections are stale (> 8 hours old).
  Optionally excludes nodes created by a specific user.
  """
  def list_community_folder_nodes(folder, exclude_creator_id \\ nil)

  def list_community_folder_nodes(%Folder{is_community: true} = folder, exclude_creator_id) do
    # Check if refresh is needed
    if needs_community_refresh?(folder) do
      refresh_community_selections(folder)
    end

    # Query the current selections
    query =
      CommunityNodeSelection
      |> where([s], s.folder_id == ^folder.id)
      |> join(:inner, [s], n in Node, on: n.id == s.node_id)

    # Optionally exclude nodes created by a specific user
    query =
      if exclude_creator_id do
        query |> where([s, n], n.created_by_id != ^exclude_creator_id)
      else
        query
      end

    query
    |> select([s, n], n)
    |> Repo.all()
    |> Repo.preload(:created_by)
    |> Enum.map(&add_node_activity/1)
    |> Enum.reject(fn node -> calculate_decay_state(node) == :gone end)
  end

  def list_community_folder_nodes(_folder, _exclude_creator_id), do: []

  @doc """
  Counts nodes currently selected for a community folder.
  """
  def count_community_folder_nodes(%Folder{is_community: true} = folder) do
    CommunityNodeSelection
    |> where([s], s.folder_id == ^folder.id)
    |> Repo.aggregate(:count, :id)
  end

  def count_community_folder_nodes(_folder), do: 0

  @doc """
  Checks if a community folder needs its selections refreshed.
  Returns true if last_refreshed_at is nil or older than 8 hours.
  """
  def needs_community_refresh?(%Folder{is_community: true, last_refreshed_at: nil}), do: true

  def needs_community_refresh?(%Folder{is_community: true, last_refreshed_at: last_refreshed}) do
    seconds_since = DateTime.diff(DateTime.utc_now(), last_refreshed, :second)
    seconds_since >= @community_refresh_interval_seconds
  end

  def needs_community_refresh?(_folder), do: false

  @doc """
  Refreshes the community folder selections.
  Selects 4 random from recent (48h) + 4 weighted by engagement.
  """
  def refresh_community_selections(%Folder{is_community: true} = folder) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    forty_eight_hours_ago = DateTime.add(now, -48 * 60 * 60, :second)

    # Get all user-created nodes that aren't decayed
    all_user_nodes = list_user_created_nodes()

    # Split into recent (last 48h) and all eligible
    recent_nodes = Enum.filter(all_user_nodes, fn node ->
      DateTime.compare(node.inserted_at, forty_eight_hours_ago) == :gt
    end)

    # Get message counts for weighting
    message_counts = get_node_message_counts(Enum.map(all_user_nodes, & &1.id))

    # Select 4 random from recent (or fewer if not enough)
    random_selections =
      recent_nodes
      |> Enum.shuffle()
      |> Enum.take(4)

    random_ids = MapSet.new(Enum.map(random_selections, & &1.id))

    # Select 4 weighted from remaining nodes (excluding already selected)
    remaining_nodes = Enum.reject(all_user_nodes, fn n -> MapSet.member?(random_ids, n.id) end)

    weighted_selections =
      remaining_nodes
      |> weighted_random_select(4, message_counts)

    # Clear existing selections
    CommunityNodeSelection
    |> where([s], s.folder_id == ^folder.id)
    |> Repo.delete_all()

    # Insert new selections
    all_selections =
      Enum.map(random_selections, fn node ->
        %{
          folder_id: folder.id,
          node_id: node.id,
          selection_type: "random",
          selected_at: now,
          inserted_at: now,
          updated_at: now
        }
      end) ++
        Enum.map(weighted_selections, fn node ->
          %{
            folder_id: folder.id,
            node_id: node.id,
            selection_type: "weighted",
            selected_at: now,
            inserted_at: now,
            updated_at: now
          }
        end)

    if length(all_selections) > 0 do
      Repo.insert_all(CommunityNodeSelection, all_selections)
    end

    # Update the folder's last_refreshed_at
    folder
    |> Folder.changeset(%{last_refreshed_at: now})
    |> Repo.update()

    :ok
  end

  def refresh_community_selections(_folder), do: :ok

  # Lists all user-created nodes (nodes with created_by_id set)
  defp list_user_created_nodes do
    Node
    |> where([n], not is_nil(n.created_by_id))
    |> Repo.all()
    |> Repo.preload(:created_by)
    |> Enum.map(&add_node_activity/1)
    |> Enum.reject(fn node -> calculate_decay_state(node) == :gone end)
  end

  # Gets message counts for a list of node IDs
  defp get_node_message_counts(node_ids) when node_ids == [], do: %{}

  defp get_node_message_counts(node_ids) do
    Message
    |> where([m], m.node_id in ^node_ids)
    |> group_by([m], m.node_id)
    |> select([m], {m.node_id, count(m.id)})
    |> Repo.all()
    |> Map.new()
  end

  # Weighted random selection based on message counts
  # Higher message count = higher probability of selection
  defp weighted_random_select(nodes, count, _message_counts) when length(nodes) <= count do
    nodes
  end

  defp weighted_random_select(nodes, count, message_counts) do
    # Build weighted list: each node gets weight = message_count + 1 (so nodes with 0 messages still have a chance)
    weighted_nodes =
      Enum.map(nodes, fn node ->
        weight = Map.get(message_counts, node.id, 0) + 1
        {node, weight}
      end)

    do_weighted_select(weighted_nodes, count, [])
  end

  defp do_weighted_select(_weighted_nodes, 0, acc), do: acc
  defp do_weighted_select([], _count, acc), do: acc

  defp do_weighted_select(weighted_nodes, count, acc) do
    total_weight = Enum.reduce(weighted_nodes, 0, fn {_node, weight}, sum -> sum + weight end)

    if total_weight == 0 do
      acc
    else
      # Pick a random point in the total weight
      random_point = :rand.uniform(total_weight)

      # Find which node that point falls into
      {selected_node, _} = find_weighted_selection(weighted_nodes, random_point, 0)

      # Remove selected node and recurse
      remaining = Enum.reject(weighted_nodes, fn {n, _} -> n.id == selected_node.id end)
      do_weighted_select(remaining, count - 1, [selected_node | acc])
    end
  end

  defp find_weighted_selection([{node, weight} | rest], target, cumulative) do
    new_cumulative = cumulative + weight

    if target <= new_cumulative do
      {node, weight}
    else
      find_weighted_selection(rest, target, new_cumulative)
    end
  end

  defp find_weighted_selection([], _target, _cumulative) do
    # Fallback - shouldn't happen but just in case
    {nil, 0}
  end

  # Add activity info to a node
  defp add_node_activity(node) do
    one_hour_ago = DateTime.utc_now() |> DateTime.add(-3600, :second)

    message_count =
      Message
      |> where([m], m.node_id == ^node.id and m.inserted_at >= ^one_hour_ago)
      |> Repo.aggregate(:count, :id)

    activity_level = calculate_activity_level(message_count)

    node
    |> Map.put(:activity, %{count: message_count, level: activity_level})
    |> Map.put(:decay, calculate_decay_state(node))
  end

  defp calculate_activity_level(count) when count == 0, do: :dormant
  defp calculate_activity_level(count) when count < 3, do: :quiet
  defp calculate_activity_level(count) when count < 10, do: :active
  defp calculate_activity_level(_count), do: :buzzing

  # Decay thresholds in days
  @fresh_threshold_days 1
  @quiet_threshold_days 3
  @fading_threshold_days 5

  defp calculate_decay_state(%Node{last_activity_at: nil}), do: :fresh

  defp calculate_decay_state(%Node{last_activity_at: last_activity}) do
    days_since = DateTime.diff(DateTime.utc_now(), last_activity, :day)

    cond do
      days_since < @fresh_threshold_days -> :fresh
      days_since < @quiet_threshold_days -> :quiet
      days_since < @fading_threshold_days -> :fading
      true -> :gone
    end
  end

  defp calculate_decay_state(%{last_activity_at: last_activity}) do
    calculate_decay_state(%Node{last_activity_at: last_activity})
  end
end
