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

  def list_nodes_in_bounds(min_x, max_x, min_y, max_y) do
    Node
    |> where([n], n.position_x >= ^min_x and n.position_x <= ^max_x)
    |> where([n], n.position_y >= ^min_y and n.position_y <= ^max_y)
    |> Repo.all()
  end

  def get_node!(id), do: Repo.get!(Node, id)

  def get_node(id), do: Repo.get(Node, id)

  def create_node(attrs \\ %{}) do
    %Node{}
    |> Node.changeset(attrs)
    |> Repo.insert()
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

  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, message} ->
        message = Repo.preload(message, :user)
        broadcast_message(message)
        {:ok, message}
      error ->
        error
    end
  end

  defp broadcast_message(message) do
    Phoenix.PubSub.broadcast(
      Gridroom.PubSub,
      "node:#{message.node_id}",
      {:new_message, message}
    )
  end

  # Seeding

  def seed_initial_nodes! do
    nodes = [
      %{title: "The AI hiring question", description: "Where does automation end and humanity begin?", position_x: 0.0, position_y: 0.0, node_type: "debate"},
      %{title: "Sleep as resistance", description: "In a world that never stops, rest is radical.", position_x: 150.0, position_y: -80.0, node_type: "discussion"},
      %{title: "The third place is dead", description: "Where do we gather now?", position_x: -120.0, position_y: 100.0, node_type: "question"},
      %{title: "Vibes-based decision making", description: "Trust the feeling.", position_x: 200.0, position_y: 150.0, node_type: "discussion"},
      %{title: "Digital gardens", description: "Tend your corner of the internet.", position_x: -180.0, position_y: -120.0, node_type: "quiet"},
      %{title: "The loneliness epidemic", description: "Connected but alone.", position_x: 80.0, position_y: 200.0, node_type: "discussion"}
    ]

    Enum.each(nodes, fn attrs ->
      case Repo.get_by(Node, title: attrs.title) do
        nil -> create_node(attrs)
        _existing -> :ok
      end
    end)
  end
end
