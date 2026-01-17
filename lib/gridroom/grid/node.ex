defmodule Gridroom.Grid.Node do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @node_types ~w(discussion question debate quiet)

  schema "nodes" do
    field :title, :string
    field :description, :string
    field :position_x, :float, default: 0.0
    field :position_y, :float, default: 0.0
    field :node_type, :string, default: "discussion"
    field :glyph_shape, :string, default: "hexagon"
    field :glyph_color, :string, default: "#8B7355"
    field :last_activity_at, :utc_datetime
    field :sources, {:array, :map}, default: []
    field :folder_date, :date

    belongs_to :created_by, Gridroom.Accounts.User
    belongs_to :folder, Gridroom.Folders.Folder, type: :id
    has_many :messages, Gridroom.Grid.Message

    timestamps(type: :utc_datetime)
  end

  def changeset(node, attrs) do
    node
    |> cast(attrs, [:title, :description, :position_x, :position_y, :node_type, :glyph_shape, :glyph_color, :created_by_id, :last_activity_at, :sources, :folder_id, :folder_date])
    |> validate_required([:title, :position_x, :position_y])
    |> validate_inclusion(:node_type, @node_types)
  end

  def node_types, do: @node_types
end
