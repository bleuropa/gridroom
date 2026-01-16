defmodule Gridroom.Repo.Migrations.CreateConnections do
  use Ecto.Migration

  def change do
    create table(:connections, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :friend_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :met_in_node_id, references(:nodes, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:connections, [:user_id])
    create index(:connections, [:friend_id])
    create unique_index(:connections, [:user_id, :friend_id])
  end
end
