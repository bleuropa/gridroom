defmodule Gridroom.Folders.Folder do
  @moduledoc """
  Schema for MDR-style folders that categorize discussions.
  Each folder represents a topic area (sports, gossip, tech, etc.)
  with its own system prompt for fetching topics and completion message.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "folders" do
    field :slug, :string
    field :name, :string
    field :description, :string
    field :system_prompt, :string
    field :completion_message, :string
    field :icon, :string
    field :sort_order, :integer, default: 0
    field :active, :boolean, default: true

    has_many :nodes, Gridroom.Grid.Node

    timestamps(type: :utc_datetime)
  end

  def changeset(folder, attrs) do
    folder
    |> cast(attrs, [:slug, :name, :description, :system_prompt, :completion_message, :icon, :sort_order, :active])
    |> validate_required([:slug, :name, :system_prompt, :completion_message])
    |> unique_constraint(:slug)
  end
end
