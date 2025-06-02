defmodule Repo.Migrations.CreateSysAgentsAssistantsFiles do
  use Ecto.Migration

  def change do
    create table(:sys_agents_assistants_files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false, default: ""
      add :assistant_id, :integer, null: false, default: 0
      add :added, :integer, null: false, default: 0
      add :ai_file_id, :string, null: false, default: ""
      add :ai_file_size, :integer, null: false, default: 0
      add :ai_file_status, :string, null: false, default: "in_progress"
      add :locked, :integer, null: false, default: 0
      timestamps()
    end
  end
end
