defmodule Gridroom.Repo.Migrations.AddCreatedNodeIdsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :created_node_ids, {:array, :binary_id}, default: []
    end
  end
end
