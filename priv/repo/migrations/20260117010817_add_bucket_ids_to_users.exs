defmodule Gridroom.Repo.Migrations.AddBucketIdsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :bucket_ids, {:array, :binary_id}, default: []
    end
  end
end
