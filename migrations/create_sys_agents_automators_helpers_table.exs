defmodule Repo.Migrations.CreateSysAgentsAutomatorsHelpers do
  use Ecto.Migration

  def change do
    create table(:sys_agents_automators_helpers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :automator_id, :integer, null: false, default: 0
      add :helper_id, :integer, null: false, default: 0
      timestamps()
    end
  end
end
