defmodule Repo.Migrations.CreateSysProfiles do
  use Ecto.Migration

  def change do
    create table(:sys_profiles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, :integer, null: false
      add :type, :string, null: false
      add :content_id, :integer, null: false
      add :cfw_value, :integer, null: false, default: 2147483647
      add :cfw_items, :integer, null: false, default: 2147483647
      add :cfu_items, :integer, null: false, default: 2147483647
      add :cfu_locked, :integer, null: false, default: 0
      add :status, :string, null: false, default: "active"
      timestamps()
    end
    create index(:sys_profiles, [:account_id])
    create index(:sys_profiles, [:content_id])
  end
end
