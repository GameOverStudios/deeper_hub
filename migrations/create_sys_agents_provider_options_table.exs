defmodule Repo.Migrations.CreateSysAgentsProviderOptions do
  use Ecto.Migration

  def change do
    create table(:sys_agents_provider_options, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :provider_type_id, :integer, null: false, default: 0
      add :name, :string, null: false, default: ""
      add :type, :string, null: false, default: "text"
      add :title, :string, null: false, default: ""
      add :description, :string, null: false, default: "''"
      add :extra, :string, null: false, default: ""
      add :check_type, :string, null: false, default: ""
      add :check_params, :string, null: false, default: ""
      add :check_error, :string, null: false, default: ""
      add :order, :integer, null: false, default: 0
      timestamps()
    end
    create index(:sys_agents_provider_options, [:name], unique: true)
  end
end
