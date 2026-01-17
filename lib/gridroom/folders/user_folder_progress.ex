defmodule Gridroom.Folders.UserFolderProgress do
  @moduledoc """
  Tracks user progress through folder refinement.
  Each record represents a user's progress on a specific folder for a specific day.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "user_folder_progress" do
    field :date, :date
    field :refined_count, :integer, default: 0
    field :total_count, :integer
    field :completed_at, :utc_datetime

    belongs_to :user, Gridroom.Accounts.User
    belongs_to :folder, Gridroom.Folders.Folder, type: :id

    timestamps(type: :utc_datetime)
  end

  def changeset(progress, attrs) do
    progress
    |> cast(attrs, [:user_id, :folder_id, :date, :refined_count, :total_count, :completed_at])
    |> validate_required([:user_id, :folder_id, :date, :total_count])
    |> unique_constraint([:user_id, :folder_id, :date])
  end
end
