defmodule Repo.Migrations.CreateSysAgentsAutomators do
  use Ecto.Migration

  def change do
    create table(:sys_agents_automators, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false, default: ""
      add :model_id, :integer, null: false, default: 0
      add :profile_id, :integer, null: false, default: 0
      add :type, :string, null: false, default: "event"
      add :params, :string, null: false
      add :alert_unit, :string, null: false, default: ""
      add :alert_action, :string, null: false, default: ""
      add :message_id, :integer, null: false, default: 0
      add :code, :string, null: false
      add :added, :integer, null: false, default: 0
      add :messages, :integer, null: false, default: 0
      add :status, :string, null: false, default: "auto"
      add :active, :integer, null: false, default: 0
      timestamps()
    end
  end
end
