defmodule Gridroom.Repo.Migrations.AddUserDismissedNodes do
  use Ecto.Migration

  def change do
    create table(:user_dismissed_nodes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :node_id, references(:nodes, type: :binary_id, on_delete: :delete_all), null: false
      add :dismissed_at, :utc_datetime, null: false, default: fragment("now()")
    end

    # Each user can only dismiss a node once
    create unique_index(:user_dismissed_nodes, [:user_id, :node_id])
    create index(:user_dismissed_nodes, [:user_id])
  end
end
