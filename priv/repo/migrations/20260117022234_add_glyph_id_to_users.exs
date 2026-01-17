defmodule Gridroom.Repo.Migrations.AddGlyphIdToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :glyph_id, :integer
    end

    # Set random glyph IDs for existing users (0-681 range)
    execute "UPDATE users SET glyph_id = floor(random() * 682)::integer WHERE glyph_id IS NULL",
            "SELECT 1"
  end
end
