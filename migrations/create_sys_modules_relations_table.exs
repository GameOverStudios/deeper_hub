defmodule Repo.Migrations.CreateSysModulesRelations do
  use Ecto.Migration

  def change do
    create table(:sys_modules_relations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :module, :string, null: false, default: ""
      add :on_install, :string, null: false, default: ""
      add :on_uninstall, :string, null: false, default: ""
      add :on_enable, :string, null: false, default: ""
      add :on_disable, :string, null: false, default: ""
      timestamps()
    end
  end
end
