defmodule Gridroom.Repo.Migrations.CreatePods do
  use Ecto.Migration

  def change do
    create table(:pods, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :creator_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create table(:pod_memberships, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :pod_id, references(:pods, type: :binary_id, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :role, :string, null: false, default: "member"
      add :status, :string, null: false, default: "pending"
      add :invited_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:pod_memberships, [:pod_id])
    create index(:pod_memberships, [:user_id])
    create unique_index(:pod_memberships, [:pod_id, :user_id])

    # Add pod_id to messages for scoping
    alter table(:messages) do
      add :pod_id, references(:pods, type: :binary_id, on_delete: :delete_all)
      add :forwarded_from_id, references(:messages, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:messages, [:pod_id])
  end
end
