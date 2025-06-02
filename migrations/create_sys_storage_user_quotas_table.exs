defmodule Repo.Migrations.CreateSysStorageUserQuotas do
  use Ecto.Migration

  def change do
    create table(:sys_storage_user_quotas, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :profile_id, :integer, null: false
      add :current_size, :integer, null: false
      add :current_number, :integer, null: false
      add :ts, :integer, null: false
      timestamps()
    end
  end
end
