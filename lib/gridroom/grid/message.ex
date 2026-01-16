defmodule Gridroom.Grid.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "messages" do
    field :content, :string

    belongs_to :node, Gridroom.Grid.Node
    belongs_to :user, Gridroom.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :node_id, :user_id])
    |> validate_required([:content, :node_id])
    |> validate_length(:content, min: 1, max: 2000)
    |> foreign_key_constraint(:node_id)
    |> foreign_key_constraint(:user_id)
  end
end
