defmodule Gridroom.Connections.Connection do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "connections" do
    belongs_to :user, Gridroom.Accounts.User
    belongs_to :friend, Gridroom.Accounts.User
    belongs_to :met_in_node, Gridroom.Grid.Node

    timestamps(type: :utc_datetime)
  end

  def changeset(connection, attrs) do
    connection
    |> cast(attrs, [:user_id, :friend_id, :met_in_node_id])
    |> validate_required([:user_id, :friend_id])
    |> unique_constraint([:user_id, :friend_id])
  end
end
