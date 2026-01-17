defmodule Gridroom.Repo.Migrations.AddSourceApiToNodes do
  use Ecto.Migration

  def change do
    alter table(:nodes) do
      add :source_api, :string, default: "grok"
    end

    create index(:nodes, [:source_api])
  end
end
