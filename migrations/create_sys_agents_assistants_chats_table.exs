defmodule Repo.Migrations.CreateSysAgentsAssistantsChats do
  use Ecto.Migration

  def change do
    create table(:sys_agents_assistants_chats, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false, default: ""
      add :type, :integer, null: false, default: 1
      add :assistant_id, :integer, null: false, default: 0
      add :description, :string, null: false
      add :message_id, :integer, null: false, default: 0
      add :messages, :integer, null: false, default: 0
      add :added, :integer, null: false, default: 0
      add :ai_thread_id, :string, null: false, default: ""
      add :ai_file_id, :string, null: false, default: ""
      add :stored, :integer, null: false, default: 0
      timestamps()
    end
  end
end
