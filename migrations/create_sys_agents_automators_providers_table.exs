defmodule Repo.Migrations.CreateSysAgentsAutomatorsProviders do
  use Ecto.Migration

  def change do
    create table(:sys_agents_automators_providers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :automator_id, :integer, null: false, default: 0
      add :provider_id, :integer, null: false, default: 0
      timestamps()
    end
  end
end
