defmodule Gridroom.Repo.Migrations.AddResonanceToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :resonance, :integer, default: 50, null: false
    end

    # Index for finding low-resonance users (for moderation queries)
    create index(:users, [:resonance])
  end
end
