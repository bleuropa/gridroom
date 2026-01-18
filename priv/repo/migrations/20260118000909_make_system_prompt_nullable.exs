defmodule Gridroom.Repo.Migrations.MakeSystemPromptNullable do
  use Ecto.Migration

  def change do
    # Make system_prompt nullable for community folders (they don't use AI generation)
    alter table(:folders) do
      modify :system_prompt, :text, null: true
    end
  end
end
