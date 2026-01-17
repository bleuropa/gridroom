defmodule Gridroom.Pods.Pod do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "pods" do
    field :name, :string

    belongs_to :creator, Gridroom.Accounts.User
    has_many :memberships, Gridroom.Pods.PodMembership
    has_many :members, through: [:memberships, :user]

    timestamps(type: :utc_datetime)
  end

  def changeset(pod, attrs) do
    pod
    |> cast(attrs, [:name, :creator_id])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 50)
    |> foreign_key_constraint(:creator_id)
  end
end
