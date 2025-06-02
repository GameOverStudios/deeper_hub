defmodule Repo.Migrations.CreateSysStorageDeletions do
  use Ecto.Migration

  def change do
    create table(:sys_storage_deletions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object, :string, null: false
      add :file_id, :integer, null: false
      add :requested, :integer, null: false
      timestamps()
    end
    create index(:sys_storage_deletions, [:object])
    create index(:sys_storage_deletions, [:requested])
  end
end
