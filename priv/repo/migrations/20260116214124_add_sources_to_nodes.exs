defmodule Gridroom.Repo.Migrations.AddSourcesToNodes do
  use Ecto.Migration

  def change do
    alter table(:nodes) do
      add :sources, {:array, :map}, default: []
    end
  end
end
