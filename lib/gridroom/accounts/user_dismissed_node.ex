defmodule Gridroom.Accounts.UserDismissedNode do
  @moduledoc """
  Tracks which nodes a user has dismissed.
  Dismissed nodes won't appear in emergence queue.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "user_dismissed_nodes" do
    belongs_to :user, Gridroom.Accounts.User
    belongs_to :node, Gridroom.Grid.Node

    field :dismissed_at, :utc_datetime
  end

  def changeset(dismissed_node, attrs) do
    dismissed_node
    |> cast(attrs, [:user_id, :node_id, :dismissed_at])
    |> validate_required([:user_id, :node_id])
    |> unique_constraint([:user_id, :node_id])
  end
end
