defmodule Gridroom.Resonance.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "resonance_transactions" do
    field :amount, :integer
    field :reason, :string

    belongs_to :user, Gridroom.Accounts.User
    belongs_to :source_user, Gridroom.Accounts.User
    belongs_to :node, Gridroom.Grid.Node
    belongs_to :message, Gridroom.Grid.Message

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @reasons ~w(
    affirm_received
    dismiss_received
    message_replied
    node_visited
    node_chat
    remembered
    icebreaker
    exploration
    daily_return
    spam_detected
    abandoned_node
  )

  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:user_id, :amount, :reason, :source_user_id, :node_id, :message_id])
    |> validate_required([:user_id, :amount, :reason])
    |> validate_inclusion(:reason, @reasons)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:source_user_id)
    |> foreign_key_constraint(:node_id)
    |> foreign_key_constraint(:message_id)
  end

  def reasons, do: @reasons
end
