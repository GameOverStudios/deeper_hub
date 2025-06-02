defmodule Repo.Migrations.CreateSysAgentsHelpers do
  use Ecto.Migration

  def change do
    create table(:sys_agents_helpers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :model_id, :integer, null: false, default: 0
      add :profile_id, :integer, null: false, default: 0
      add :description, :string, null: false
      add :prompt, :string
      add :added, :integer, null: false, default: 0
      add :active, :integer, null: false, default: 0
      timestamps()
    end
    create index(:sys_agents_helpers, [:name], unique: true)
  end
end
