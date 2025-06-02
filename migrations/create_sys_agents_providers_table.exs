defmodule Repo.Migrations.CreateSysAgentsProviders do
  use Ecto.Migration

  def change do
    create table(:sys_agents_providers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false, default: ""
      add :type_id, :integer, null: false, default: 0
      add :profile_id, :integer, null: false, default: 0
      add :added, :integer, null: false, default: 0
      add :active, :integer, null: false, default: 1
      timestamps()
    end
    create index(:sys_agents_providers, [:name], unique: true)
  end
end
