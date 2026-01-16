defmodule Gridroom.Repo.Migrations.CreateResonanceTransactions do
  use Ecto.Migration

  def change do
    create table(:resonance_transactions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :amount, :integer, null: false
      add :reason, :string, null: false
      # Who caused this transaction (e.g., who affirmed/dismissed)
      add :source_user_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      # Context (which node/message this relates to)
      add :node_id, references(:nodes, type: :binary_id, on_delete: :nilify_all)
      add :message_id, references(:messages, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:resonance_transactions, [:user_id])
    create index(:resonance_transactions, [:user_id, :inserted_at])

    # Track feedback cooldowns to prevent spam
    create table(:feedback_cooldowns, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :target_user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :last_feedback_at, :utc_datetime, null: false
    end

    create unique_index(:feedback_cooldowns, [:user_id, :target_user_id])
  end
end
