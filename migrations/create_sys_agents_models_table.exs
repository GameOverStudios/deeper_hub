defmodule Repo.Migrations.CreateSysAgentsModels do
  use Ecto.Migration

  def change do
    create table(:sys_agents_models, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false, default: ""
      add :title, :string, null: false, default: ""
      add :key, :string, null: false, default: ""
      add :params, :string, null: false
      add :for_asst, :integer, null: false, default: 0
      add :active, :integer, null: false, default: 1
      add :hidden, :integer, null: false, default: 0
      add :class_name, :string, null: false, default: ""
      add :class_file, :string, null: false, default: ""
      timestamps()
    end
    create index(:sys_agents_models, [:name], unique: true)
  end
end
