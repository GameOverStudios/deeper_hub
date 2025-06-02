defmodule Repo.Migrations.CreateSysKeys do
  use Ecto.Migration

  def change do
    create table(:sys_keys, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :key, :string, null: false
      add :data, :string, null: false
      add :expire, :integer, null: false
      add :salt, :string, null: false
      timestamps()
    end
  end
end
