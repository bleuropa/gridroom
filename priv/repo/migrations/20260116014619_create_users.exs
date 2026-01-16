defmodule Gridroom.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :session_id, :string, null: false
      add :glyph_shape, :string, null: false, default: "circle"
      add :glyph_color, :string, null: false, default: "#D4A574"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:session_id])
  end
end
