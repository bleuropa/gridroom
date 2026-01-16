defmodule Gridroom.Repo.Migrations.MakeSessionIdNullable do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :session_id, :string, null: true, from: {:string, null: false}
    end
  end
end
