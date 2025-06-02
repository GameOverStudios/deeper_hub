defmodule Repo.Migrations.CreateSysAgentsProvidersValues do
  use Ecto.Migration

  def change do
    create table(:sys_agents_providers_values, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :provider_id, :integer, null: false, default: 0
      add :option_id, :integer, null: false, default: 0
      add :value, :string, null: false, default: ""
      timestamps()
    end
    create index(:sys_agents_providers_values, [:provider_id])
  end
end
