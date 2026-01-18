defmodule Gridroom.Accounts do
  @moduledoc """
  The Accounts context - manages users (both anonymous and registered).
  """

  import Ecto.Query

  alias Gridroom.Repo
  alias Gridroom.Accounts.User
  alias Gridroom.Accounts.UserDismissedNode

  ## User queries

  def get_user!(id), do: Repo.get!(User, id)

  def get_user(id), do: Repo.get(User, id)

  def get_user_by_session(session_id) do
    Repo.get_by(User, session_id: session_id)
  end

  def get_user_by_username(username) when is_binary(username) do
    Repo.get_by(User, username: username)
  end

  ## Anonymous user creation

  def get_or_create_user(session_id) do
    case get_user_by_session(session_id) do
      nil ->
        user = User.new_with_random_glyph(session_id)
        Repo.insert(user)

      user ->
        {:ok, user}
    end
  end

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  ## Registration

  @doc """
  Registers a new user with username and password.
  Optionally preserves glyph from an existing anonymous user.
  """
  def register_user(attrs, opts \\ []) do
    alias Gridroom.Accounts.Glyphs

    # If an anonymous user is provided, inherit their glyph_id
    attrs =
      case Keyword.get(opts, :anonymous_user) do
        %User{glyph_id: glyph_id} when is_integer(glyph_id) ->
          Map.merge(%{"glyph_id" => glyph_id}, attrs)

        _ ->
          # New user gets random glyph
          Map.merge(%{"glyph_id" => Glyphs.random_id()}, attrs)
      end

    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns a changeset for tracking user registration changes.
  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs)
  end

  ## Authentication

  @doc """
  Authenticates a user by username and password.
  """
  def authenticate_user(username, password)
      when is_binary(username) and is_binary(password) do
    user = get_user_by_username(username)

    if User.valid_password?(user, password) do
      {:ok, user}
    else
      {:error, :invalid_credentials}
    end
  end

  ## Bucket Management

  @doc """
  Updates the user's bucket IDs (max 6).
  """
  def update_buckets(%User{} = user, bucket_ids) when is_list(bucket_ids) do
    # Ensure max 6 buckets
    bucket_ids = Enum.take(bucket_ids, 6)

    user
    |> User.bucket_changeset(%{bucket_ids: bucket_ids})
    |> Repo.update()
  end

  @doc """
  Adds a node ID to user's buckets if not full and not already present.
  Returns {:ok, user}, {:error, :buckets_full}, or {:error, :already_bucketed}.
  """
  def add_to_buckets(%User{bucket_ids: bucket_ids} = user, node_id) do
    cond do
      node_id in bucket_ids ->
        {:error, :already_bucketed}

      length(bucket_ids) >= 6 ->
        {:error, :buckets_full}

      true ->
        update_buckets(user, bucket_ids ++ [node_id])
    end
  end

  @doc """
  Removes a node ID from user's buckets by index.
  """
  def remove_from_buckets(%User{bucket_ids: bucket_ids} = user, index) when is_integer(index) do
    new_ids = List.delete_at(bucket_ids, index)
    update_buckets(user, new_ids)
  end

  @doc """
  Clears all buckets for a user.
  """
  def clear_buckets(%User{} = user) do
    update_buckets(user, [])
  end

  ## Created Nodes Management (User-created discussions, slots 7-8)

  @doc """
  Updates the user's created node IDs (max 2).
  """
  def update_created_nodes(%User{} = user, created_node_ids) when is_list(created_node_ids) do
    # Ensure max 2 created nodes
    created_node_ids = Enum.take(created_node_ids, 2)

    user
    |> User.created_nodes_changeset(%{created_node_ids: created_node_ids})
    |> Repo.update()
  end

  @doc """
  Adds a node ID to user's created nodes if not full and not already present.
  Returns {:ok, user}, {:error, :created_nodes_full}, or {:error, :already_created}.
  """
  def add_to_created_nodes(%User{created_node_ids: created_node_ids} = user, node_id) do
    cond do
      node_id in created_node_ids ->
        {:error, :already_created}

      length(created_node_ids) >= 2 ->
        {:error, :created_nodes_full}

      true ->
        update_created_nodes(user, created_node_ids ++ [node_id])
    end
  end

  @doc """
  Removes a node ID from user's created nodes by index.
  """
  def remove_from_created_nodes(%User{created_node_ids: created_node_ids} = user, index)
      when is_integer(index) do
    new_ids = List.delete_at(created_node_ids, index)
    update_created_nodes(user, new_ids)
  end

  @doc """
  Removes a node ID from user's created nodes by node ID.
  """
  def remove_from_created_nodes_by_id(%User{created_node_ids: created_node_ids} = user, node_id) do
    new_ids = Enum.reject(created_node_ids, &(&1 == node_id))
    update_created_nodes(user, new_ids)
  end

  ## Dismissal Management

  @doc """
  Dismisses a node for a user. The node won't appear in emergence again.
  Uses upsert to handle duplicates gracefully.
  """
  def dismiss_node(%User{id: user_id}, node_id) do
    %UserDismissedNode{}
    |> UserDismissedNode.changeset(%{
      user_id: user_id,
      node_id: node_id,
      dismissed_at: DateTime.utc_now()
    })
    |> Repo.insert(
      on_conflict: :nothing,
      conflict_target: [:user_id, :node_id]
    )
  end

  @doc """
  Returns list of node IDs that user has dismissed.
  """
  def list_dismissed_node_ids(%User{id: user_id}) do
    from(d in UserDismissedNode,
      where: d.user_id == ^user_id,
      select: d.node_id
    )
    |> Repo.all()
  end

  @doc """
  Checks if a user has dismissed a specific node.
  """
  def node_dismissed?(%User{id: user_id}, node_id) do
    from(d in UserDismissedNode,
      where: d.user_id == ^user_id and d.node_id == ^node_id
    )
    |> Repo.exists?()
  end
end
