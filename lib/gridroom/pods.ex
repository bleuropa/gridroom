defmodule Gridroom.Pods do
  @moduledoc """
  The Pods context - manages private groups for discussions.

  Pods are global entities that allow users to have private conversations
  within discussions. Only pod members can see messages posted to a pod view.
  """

  import Ecto.Query
  alias Gridroom.Repo
  alias Gridroom.Pods.{Pod, PodMembership}

  # Pod CRUD

  @doc """
  Creates a new pod with the given user as creator.
  Automatically adds the creator as an accepted member with "creator" role.
  """
  def create_pod(attrs, creator_id) do
    Repo.transaction(fn ->
      with {:ok, pod} <- do_create_pod(attrs, creator_id),
           {:ok, _membership} <- add_creator_membership(pod, creator_id) do
        pod
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  defp do_create_pod(attrs, creator_id) do
    %Pod{}
    |> Pod.changeset(Map.put(attrs, :creator_id, creator_id))
    |> Repo.insert()
  end

  defp add_creator_membership(pod, creator_id) do
    %PodMembership{}
    |> PodMembership.changeset(%{
      pod_id: pod.id,
      user_id: creator_id,
      role: "creator",
      status: "accepted"
    })
    |> Repo.insert()
  end

  @doc """
  Gets a pod by ID.
  """
  def get_pod(id), do: Repo.get(Pod, id)

  @doc """
  Gets a pod by ID with memberships preloaded.
  """
  def get_pod_with_members(id) do
    Pod
    |> Repo.get(id)
    |> Repo.preload(memberships: :user)
  end

  @doc """
  Lists all pods a user is a member of (with accepted status).
  """
  def list_user_pods(user_id) do
    from(p in Pod,
      join: pm in PodMembership,
      on: pm.pod_id == p.id,
      where: pm.user_id == ^user_id and pm.status == "accepted",
      preload: [memberships: ^accepted_memberships_query()]
    )
    |> Repo.all()
  end

  defp accepted_memberships_query do
    from(pm in PodMembership, where: pm.status == "accepted", preload: :user)
  end

  @doc """
  Lists all pods a user has pending invitations for.
  """
  def list_pending_invitations(user_id) do
    from(p in Pod,
      join: pm in PodMembership,
      on: pm.pod_id == p.id,
      where: pm.user_id == ^user_id and pm.status == "pending",
      preload: [:creator, memberships: ^accepted_memberships_query()]
    )
    |> Repo.all()
  end

  # Membership management

  @doc """
  Invites a user to a pod. Creates a membership with "pending" status.
  Returns error if user is already a member.
  """
  def invite_user(pod_id, user_id, invited_by_id) do
    %PodMembership{}
    |> PodMembership.changeset(%{
      pod_id: pod_id,
      user_id: user_id,
      invited_by_id: invited_by_id,
      status: "pending",
      role: "member"
    })
    |> Repo.insert()
  end

  @doc """
  Accepts a pending invitation.
  """
  def accept_invitation(pod_id, user_id) do
    case get_membership(pod_id, user_id) do
      nil ->
        {:error, :not_found}

      %{status: "pending"} = membership ->
        membership
        |> PodMembership.accept_changeset()
        |> Repo.update()

      %{status: "accepted"} ->
        {:error, :already_accepted}

      _ ->
        {:error, :invalid_status}
    end
  end

  @doc """
  Declines a pending invitation.
  """
  def decline_invitation(pod_id, user_id) do
    case get_membership(pod_id, user_id) do
      nil ->
        {:error, :not_found}

      %{status: "pending"} = membership ->
        membership
        |> PodMembership.decline_changeset()
        |> Repo.update()

      _ ->
        {:error, :invalid_status}
    end
  end

  @doc """
  Gets a user's membership in a pod.
  """
  def get_membership(pod_id, user_id) do
    from(pm in PodMembership,
      where: pm.pod_id == ^pod_id and pm.user_id == ^user_id
    )
    |> Repo.one()
  end

  @doc """
  Checks if a user is an accepted member of a pod.
  """
  def member?(pod_id, user_id) do
    from(pm in PodMembership,
      where: pm.pod_id == ^pod_id and pm.user_id == ^user_id and pm.status == "accepted"
    )
    |> Repo.exists?()
  end

  @doc """
  Lists all accepted members of a pod.
  """
  def list_pod_members(pod_id) do
    from(pm in PodMembership,
      where: pm.pod_id == ^pod_id and pm.status == "accepted",
      preload: :user
    )
    |> Repo.all()
    |> Enum.map(& &1.user)
  end

  @doc """
  Removes a user from a pod (for leaving or being removed).
  """
  def remove_member(pod_id, user_id) do
    from(pm in PodMembership,
      where: pm.pod_id == ^pod_id and pm.user_id == ^user_id
    )
    |> Repo.delete_all()
  end

  @doc """
  Deletes a pod. Only callable by creator.
  """
  def delete_pod(pod_id, user_id) do
    case get_pod(pod_id) do
      nil ->
        {:error, :not_found}

      %{creator_id: ^user_id} = pod ->
        Repo.delete(pod)

      _ ->
        {:error, :unauthorized}
    end
  end
end
