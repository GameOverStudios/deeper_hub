defmodule Repo.Migrations.CreateSysStorageGhosts do
  use Ecto.Migration

  def change do
    create table(:sys_storage_ghosts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :iid, :integer, null: false
      add :id, :integer, null: false
      add :profile_id, :integer, null: false
      add :object, :string, null: false
      add :content_id, :integer, null: false
      add :created, :integer, null: false
      add :order, :integer, null: false, default: 0
      timestamps()
    end
    create index(:sys_storage_ghosts, [:profile_id])
    create index(:sys_storage_ghosts, [:created])
  end
end
