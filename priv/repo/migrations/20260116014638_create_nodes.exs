defmodule Gridroom.Repo.Migrations.CreateNodes do
  use Ecto.Migration

  def change do
    create table(:nodes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :description, :text
      add :position_x, :float, null: false, default: 0.0
      add :position_y, :float, null: false, default: 0.0
      add :node_type, :string, null: false, default: "discussion"
      add :glyph_shape, :string, null: false, default: "hexagon"
      add :glyph_color, :string, null: false, default: "#8B7355"

      timestamps(type: :utc_datetime)
    end

    create index(:nodes, [:position_x, :position_y])
  end
end
