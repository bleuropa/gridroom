defmodule Gridroom.Connections.UserNodeVisit do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "user_node_visits" do
    belongs_to :user, Gridroom.Accounts.User
    belongs_to :node, Gridroom.Grid.Node
    field :visited_at, :utc_datetime
  end

  def changeset(visit, attrs) do
    visit
    |> cast(attrs, [:user_id, :node_id, :visited_at])
    |> validate_required([:user_id, :node_id, :visited_at])
  end
end
