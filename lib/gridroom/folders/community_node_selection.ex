defmodule Gridroom.Folders.CommunityNodeSelection do
  @moduledoc """
  Tracks which nodes are currently selected for display in community folders.
  Selections are refreshed every 8 hours with a mix of random and weighted picks.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "community_node_selections" do
    field :selection_type, :string  # "random" or "weighted"
    field :selected_at, :utc_datetime

    belongs_to :folder, Gridroom.Folders.Folder, type: :id
    belongs_to :node, Gridroom.Grid.Node

    timestamps(type: :utc_datetime)
  end

  def changeset(selection, attrs) do
    selection
    |> cast(attrs, [:folder_id, :node_id, :selection_type, :selected_at])
    |> validate_required([:folder_id, :node_id, :selection_type, :selected_at])
    |> validate_inclusion(:selection_type, ["random", "weighted"])
    |> unique_constraint([:folder_id, :node_id])
  end
end
