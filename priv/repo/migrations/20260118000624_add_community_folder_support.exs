defmodule Gridroom.Repo.Migrations.AddCommunityFolderSupport do
  use Ecto.Migration

  def change do
    # Add community folder flags to folders table
    alter table(:folders) do
      add :is_community, :boolean, default: false
      add :last_refreshed_at, :utc_datetime
    end

    # Table to store selected nodes for community folders
    # This gets refreshed every 8 hours with a mix of random + weighted selections
    create table(:community_node_selections, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :folder_id, references(:folders, on_delete: :delete_all), null: false
      add :node_id, references(:nodes, type: :binary_id, on_delete: :delete_all), null: false
      add :selection_type, :string, null: false  # "random" or "weighted"
      add :selected_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:community_node_selections, [:folder_id])
    create unique_index(:community_node_selections, [:folder_id, :node_id])
  end
end
