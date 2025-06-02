defmodule Repo.Migrations.CreateSysAgentsProviderTypes do
  use Ecto.Migration

  def change do
    create table(:sys_agents_provider_types, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false, default: ""
      add :title, :string, null: false, default: ""
      add :option_prefix, :string, null: false, default: ""
      add :active, :integer, null: false, default: 0
      add :order, :integer, null: false, default: 0
      add :class_name, :string, null: false, default: ""
      add :class_file, :string, null: false, default: ""
      timestamps()
    end
  end
end
