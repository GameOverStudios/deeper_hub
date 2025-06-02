defmodule Repo.Migrations.CreateSysObjectsStorage do
  use Ecto.Migration

  def change do
    create table(:sys_objects_storage, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object, :string, null: false
      add :engine, :string, null: false
      add :params, :string, null: false
      add :token_life, :integer, null: false
      add :cache_control, :integer, null: false
      add :levels, :integer, null: false
      add :table_files, :string, null: false
      add :ext_mode, :string, null: false
      add :ext_allow, :string, null: false
      add :ext_deny, :string, null: false
      add :quota_size, :integer, null: false
      add :current_size, :integer, null: false
      add :quota_number, :integer, null: false
      add :current_number, :integer, null: false
      add :max_file_size, :integer, null: false
      add :ts, :integer, null: false
      timestamps()
    end
    create index(:sys_objects_storage, [:object], unique: true)
  end
end
