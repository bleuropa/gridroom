defmodule Gridroom.Connections do
  @moduledoc """
  Context for managing user connections (friends) and activity tracking.
  """

  import Ecto.Query
  alias Gridroom.Repo
  alias Gridroom.Connections.{Connection, UserNodeVisit}
  alias Gridroom.Accounts.User

  # Connections / Friends

  @doc """
  Creates a one-way connection (user "remembers" friend).
  """
  def remember_user(%User{} = user, %User{} = friend, opts \\ []) do
    met_in_node_id = Keyword.get(opts, :met_in_node_id)

    %Connection{}
    |> Connection.changeset(%{
      user_id: user.id,
      friend_id: friend.id,
      met_in_node_id: met_in_node_id
    })
    |> Repo.insert()
  end

  @doc """
  Removes a connection (user "forgets" friend).
  """
  def forget_user(%User{} = user, friend_id) do
    Connection
    |> where([c], c.user_id == ^user.id and c.friend_id == ^friend_id)
    |> Repo.delete_all()

    :ok
  end

  @doc """
  Checks if user has remembered another user.
  """
  def remembers?(%User{} = user, friend_id) do
    Connection
    |> where([c], c.user_id == ^user.id and c.friend_id == ^friend_id)
    |> Repo.exists?()
  end

  @doc """
  Lists all users that this user has remembered.
  """
  def list_remembered_users(%User{} = user) do
    Connection
    |> where([c], c.user_id == ^user.id)
    |> join(:inner, [c], f in User, on: f.id == c.friend_id)
    |> select([c, f], f)
    |> Repo.all()
  end

  # Activity Tracking

  @doc """
  Records a user visiting a node.
  """
  def record_visit(%User{} = user, node_id) do
    %UserNodeVisit{}
    |> UserNodeVisit.changeset(%{
      user_id: user.id,
      node_id: node_id,
      visited_at: DateTime.utc_now()
    })
    |> Repo.insert()
  end

  @doc """
  Gets recent node visits for a user.
  """
  def recent_visits(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)

    UserNodeVisit
    |> where([v], v.user_id == ^user_id)
    |> order_by([v], desc: v.visited_at)
    |> limit(^limit)
    |> preload(:node)
    |> Repo.all()
  end

  @doc """
  Gets recent visits with node info for display.
  Returns list of %{node: node, visited_at: datetime}.
  """
  def recent_activity(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 5)

    UserNodeVisit
    |> where([v], v.user_id == ^user_id)
    |> order_by([v], desc: v.visited_at)
    |> limit(^limit)
    |> join(:inner, [v], n in Gridroom.Grid.Node, on: n.id == v.node_id)
    |> select([v, n], %{
      node_id: n.id,
      node_title: n.title,
      node_type: n.node_type,
      visited_at: v.visited_at
    })
    |> Repo.all()
  end
end
