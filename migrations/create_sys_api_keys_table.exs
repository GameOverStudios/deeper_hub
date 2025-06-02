defmodule Repo.Migrations.CreateSysApiKeys do
  use Ecto.Migration

  def change do
    create table(:sys_api_keys, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :key, :string, null: false
      add :order, :integer, null: false
      timestamps()
    end
  end
end
