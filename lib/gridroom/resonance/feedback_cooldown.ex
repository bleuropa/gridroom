defmodule Gridroom.Resonance.FeedbackCooldown do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "feedback_cooldowns" do
    belongs_to :user, Gridroom.Accounts.User
    belongs_to :target_user, Gridroom.Accounts.User
    field :last_feedback_at, :utc_datetime
  end

  def changeset(cooldown, attrs) do
    cooldown
    |> cast(attrs, [:user_id, :target_user_id, :last_feedback_at])
    |> validate_required([:user_id, :target_user_id, :last_feedback_at])
    |> unique_constraint([:user_id, :target_user_id])
  end
end
