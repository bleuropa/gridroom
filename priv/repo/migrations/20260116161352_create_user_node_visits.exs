defmodule Gridroom.Repo.Migrations.CreateUserNodeVisits do
  use Ecto.Migration

  def change do
    create table(:user_node_visits, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :node_id, references(:nodes, type: :binary_id, on_delete: :delete_all), null: false
      add :visited_at, :utc_datetime, null: false
    end

    create index(:user_node_visits, [:user_id])
    create index(:user_node_visits, [:node_id])
    create index(:user_node_visits, [:user_id, :visited_at])
  end
end
