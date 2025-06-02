defmodule Repo.Migrations.CreateSysStorageTokens do
  use Ecto.Migration

  def change do
    create table(:sys_storage_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :iid, :integer, null: false
      add :id, :integer, null: false
      add :object, :string, null: false
      add :hash, :string, null: false
      add :created, :integer, null: false
      timestamps()
    end
    create index(:sys_storage_tokens, [:created])
  end
end
