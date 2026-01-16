defmodule Gridroom.Repo.Migrations.AddLastActivityAtToNodes do
  use Ecto.Migration

  def change do
    alter table(:nodes) do
      add :last_activity_at, :utc_datetime
    end

    # Backfill existing nodes: use inserted_at as last_activity_at
    execute "UPDATE nodes SET last_activity_at = inserted_at WHERE last_activity_at IS NULL",
            "SELECT 1"

    create index(:nodes, [:last_activity_at])
  end
end
