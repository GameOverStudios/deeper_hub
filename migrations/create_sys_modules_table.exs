defmodule Repo.Migrations.CreateSysModules do
  use Ecto.Migration

  def change do
    create table(:sys_modules, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string, null: false, default: "module"
      add :subtypes, :integer, null: false, default: 0
      add :name, :string, null: false, default: ""
      add :title, :string, null: false, default: ""
      add :vendor, :string, null: false, default: ""
      add :version, :string, null: false, default: ""
      add :help_url, :string, null: false, default: ""
      add :path, :string, null: false, default: ""
      add :uri, :string, null: false, default: ""
      add :class_prefix, :string, null: false, default: ""
      add :db_prefix, :string, null: false, default: ""
      add :lang_category, :string, null: false, default: ""
      add :dependencies, :string, null: false, default: ""
      add :date, :integer, null: false, default: 0
      add :enabled, :boolean, null: false, default: false
      add :pending_uninstall, :integer, null: false
      add :hash, :string, null: false, default: ""
      add :updated, :integer, null: false, default: 0
      timestamps()
    end
    create index(:sys_modules, [:name], unique: true)
    create index(:sys_modules, [:path], unique: true)
    create index(:sys_modules, [:uri], unique: true)
    create index(:sys_modules, [:class_prefix], unique: true)
    create index(:sys_modules, [:db_prefix], unique: true)
  end
end
