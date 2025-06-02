defmodule Repo.Migrations.CreateSysAgentsAssistants do
  use Ecto.Migration

  def change do
    create table(:sys_agents_assistants, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false, default: ""
      add :model_id, :integer, null: false, default: 0
      add :profile_id, :integer, null: false, default: 0
      add :description, :string, null: false
      add :prompt, :string, null: false
      add :ai_vs_id, :string, null: false, default: ""
      add :ai_asst_id, :string, null: false, default: ""
      add :added, :integer, null: false, default: 0
      add :active, :integer, null: false, default: 0
      add :hidden, :integer, null: false, default: 0
      timestamps()
    end
    create index(:sys_agents_assistants, [:name], unique: true)
  end
end
