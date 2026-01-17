defmodule Gridroom.Repo.Migrations.CreateFolders do
  use Ecto.Migration

  def change do
    # Folders table - MDR-style category bins
    create table(:folders) do
      add :slug, :string, null: false
      add :name, :string, null: false
      add :description, :text
      add :system_prompt, :text, null: false
      add :completion_message, :text, null: false
      add :icon, :string
      add :sort_order, :integer, default: 0
      add :active, :boolean, default: true

      timestamps(type: :utc_datetime)
    end

    create unique_index(:folders, [:slug])
    create index(:folders, [:active, :sort_order])

    # Link nodes to folders (a node belongs to one folder)
    alter table(:nodes) do
      add :folder_id, references(:folders, on_delete: :nilify_all)
      add :folder_date, :date  # Which day's batch this node belongs to
    end

    create index(:nodes, [:folder_id])
    create index(:nodes, [:folder_id, :folder_date])

    # Track user progress per folder per day
    create table(:user_folder_progress, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :folder_id, references(:folders, on_delete: :delete_all), null: false
      add :date, :date, null: false
      add :refined_count, :integer, default: 0
      add :total_count, :integer, null: false
      add :completed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_folder_progress, [:user_id, :folder_id, :date])
    create index(:user_folder_progress, [:user_id, :date])
    create index(:user_folder_progress, [:folder_id, :date])
  end
end
