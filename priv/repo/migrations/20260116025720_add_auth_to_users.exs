defmodule Gridroom.Repo.Migrations.AddAuthToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :username, :string
      add :hashed_password, :string
    end

    # Unique index on username for registered users
    # Allow nulls since anonymous users won't have a username
    create unique_index(:users, [:username], where: "username IS NOT NULL")
  end
end
