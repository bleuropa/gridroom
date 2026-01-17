defmodule Gridroom.Grid do
  @moduledoc """
  The Grid context - manages nodes, messages, and the infinite canvas.
  """

  import Ecto.Query
  alias Gridroom.Repo
  alias Gridroom.Grid.{Node, Message}

  # Nodes

  def list_nodes do
    Repo.all(Node)
  end

  @doc """
  Lists nodes with their activity level based on recent messages.
  Activity is calculated from messages in the last hour.
  """
  def list_nodes_with_activity do
    one_hour_ago = DateTime.utc_now() |> DateTime.add(-3600, :second)

    # Get message counts per node in the last hour
    activity_query =
      from m in Message,
        where: m.inserted_at >= ^one_hour_ago,
        group_by: m.node_id,
        select: {m.node_id, count(m.id)}

    activity_map =
      activity_query
      |> Repo.all()
      |> Map.new()

    # Get all nodes with creator and attach activity level + decay state
    Node
    |> preload(:created_by)
    |> Repo.all()
    |> Enum.map(fn node ->
      message_count = Map.get(activity_map, node.id, 0)
      activity_level = calculate_activity_level(message_count)
      decay_state = calculate_decay_state(node)

      node
      |> Map.put(:activity, %{count: message_count, level: activity_level})
      |> Map.put(:decay, decay_state)
    end)
    |> Enum.filter(fn node -> node.decay != :gone end)
  end

  defp calculate_activity_level(count) when count == 0, do: :dormant
  defp calculate_activity_level(count) when count < 3, do: :quiet
  defp calculate_activity_level(count) when count < 10, do: :active
  defp calculate_activity_level(_count), do: :buzzing

  # Decay thresholds in days (vaulted/gone after 5 days)
  @fresh_threshold_days 1
  @quiet_threshold_days 3
  @fading_threshold_days 5

  @doc """
  Calculate the decay state of a node based on last_activity_at.
  Returns :fresh, :quiet, :fading, or :gone
  """
  def calculate_decay_state(%Node{last_activity_at: nil}), do: :fresh
  def calculate_decay_state(%Node{last_activity_at: last_activity}) do
    days_since = DateTime.diff(DateTime.utc_now(), last_activity, :day)

    cond do
      days_since < @fresh_threshold_days -> :fresh
      days_since < @quiet_threshold_days -> :quiet
      days_since < @fading_threshold_days -> :fading
      true -> :gone
    end
  end

  @doc """
  Calculate the decay state for a node-like map (used with activity map).
  """
  def calculate_decay_state_for_map(%{last_activity_at: nil}), do: :fresh
  def calculate_decay_state_for_map(%{last_activity_at: last_activity}) do
    days_since = DateTime.diff(DateTime.utc_now(), last_activity, :day)

    cond do
      days_since < @fresh_threshold_days -> :fresh
      days_since < @quiet_threshold_days -> :quiet
      days_since < @fading_threshold_days -> :fading
      true -> :gone
    end
  end

  def list_nodes_in_bounds(min_x, max_x, min_y, max_y) do
    Node
    |> where([n], n.position_x >= ^min_x and n.position_x <= ^max_x)
    |> where([n], n.position_y >= ^min_y and n.position_y <= ^max_y)
    |> Repo.all()
  end

  def get_node!(id), do: Repo.get!(Node, id)

  def get_node(id), do: Repo.get(Node, id)

  @doc """
  Get a single node with activity data attached.
  Returns nil if node not found.
  """
  def get_node_with_activity(id) do
    case Repo.get(Node, id) |> Repo.preload(:created_by) do
      nil ->
        nil

      node ->
        one_hour_ago = DateTime.utc_now() |> DateTime.add(-3600, :second)

        message_count =
          from(m in Message,
            where: m.node_id == ^node.id and m.inserted_at >= ^one_hour_ago,
            select: count(m.id)
          )
          |> Repo.one()

        activity_level = calculate_activity_level(message_count)
        decay_state = calculate_decay_state(node)

        node
        |> Map.put(:activity, %{count: message_count, level: activity_level})
        |> Map.put(:decay, decay_state)
    end
  end

  def create_node(attrs \\ %{}) do
    # Set last_activity_at to now if not provided
    attrs = Map.put_new(attrs, :last_activity_at, DateTime.utc_now() |> DateTime.truncate(:second))

    %Node{}
    |> Node.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, node} ->
        broadcast_node_created(node)
        {:ok, node}

      error ->
        error
    end
  end

  defp broadcast_node_created(node) do
    # Preload creator and add activity info for consistency with list_nodes_with_activity
    node = Repo.preload(node, :created_by)

    node_with_info =
      node
      |> Map.put(:activity, %{count: 0, level: :dormant})
      |> Map.put(:decay, :fresh)

    Phoenix.PubSub.broadcast(
      Gridroom.PubSub,
      "grid:nodes",
      {:node_created, node_with_info}
    )
  end

  def update_node(%Node{} = node, attrs) do
    node
    |> Node.changeset(attrs)
    |> Repo.update()
  end

  def delete_node(%Node{} = node) do
    Repo.delete(node)
  end

  # Messages

  def get_message!(id), do: Repo.get!(Message, id)

  def get_message(id), do: Repo.get(Message, id)

  def list_messages_for_node(node_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    Message
    |> where([m], m.node_id == ^node_id)
    |> order_by([m], desc: m.inserted_at)
    |> limit(^limit)
    |> preload(:user)
    |> Repo.all()
    |> Enum.reverse()
  end

  @doc """
  Lists top affirmed messages for a node.
  Returns messages with at least min_affirmations affirmations, sorted by count.
  """
  def list_top_affirmed_messages(node_id, opts \\ []) do
    min_affirmations = Keyword.get(opts, :min_affirmations, 2)
    limit = Keyword.get(opts, :limit, 3)

    # Query to count affirmations per message
    affirm_counts =
      from(t in Gridroom.Resonance.Transaction,
        where: t.reason == "affirm_received" and not is_nil(t.message_id),
        join: m in Message, on: m.id == t.message_id,
        where: m.node_id == ^node_id,
        group_by: t.message_id,
        having: count(t.id) >= ^min_affirmations,
        select: {t.message_id, count(t.id)},
        order_by: [desc: count(t.id)],
        limit: ^limit
      )
      |> Repo.all()
      |> Map.new()

    if map_size(affirm_counts) == 0 do
      []
    else
      message_ids = Map.keys(affirm_counts)

      Message
      |> where([m], m.id in ^message_ids)
      |> preload(:user)
      |> Repo.all()
      |> Enum.map(fn msg ->
        Map.put(msg, :affirm_count, Map.get(affirm_counts, msg.id, 0))
      end)
      |> Enum.sort_by(& &1.affirm_count, :desc)
    end
  end

  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, message} ->
        message = Repo.preload(message, :user)
        # Update node's last_activity_at to keep it fresh
        touch_node_activity(message.node_id)
        broadcast_message(message)
        {:ok, message}
      error ->
        error
    end
  end

  @doc """
  Update a node's last_activity_at timestamp to now.
  Called when messages are sent or users visit.
  """
  def touch_node_activity(node_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    from(n in Node, where: n.id == ^node_id)
    |> Repo.update_all(set: [last_activity_at: now])
  end

  defp broadcast_message(message) do
    Phoenix.PubSub.broadcast(
      Gridroom.PubSub,
      "node:#{message.node_id}",
      {:new_message, message}
    )
  end
end
