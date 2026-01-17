defmodule Gridroom.Pods.PodMembership do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @roles ~w(creator admin member)
  @statuses ~w(pending accepted declined)

  schema "pod_memberships" do
    field :role, :string, default: "member"
    field :status, :string, default: "pending"

    belongs_to :pod, Gridroom.Pods.Pod
    belongs_to :user, Gridroom.Accounts.User
    belongs_to :invited_by, Gridroom.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:pod_id, :user_id, :role, :status, :invited_by_id])
    |> validate_required([:pod_id, :user_id])
    |> validate_inclusion(:role, @roles)
    |> validate_inclusion(:status, @statuses)
    |> foreign_key_constraint(:pod_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:invited_by_id)
    |> unique_constraint([:pod_id, :user_id])
  end

  def accept_changeset(membership) do
    membership
    |> change(status: "accepted")
  end

  def decline_changeset(membership) do
    membership
    |> change(status: "declined")
  end
end
