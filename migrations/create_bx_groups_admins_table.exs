defmodule Repo.Migrations.CreateBxGroupsAdmins do
  use Ecto.Migration

  def change do
    create table(:bx_groups_admins, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :group_profile_id, :integer, null: false
      add :fan_id, :integer, null: false
      add :role, :integer, null: false, default: 0
      add :order, :string, null: false, default: ""
      add :added, :integer, null: false, default: 0
      add :expired, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_groups_admins, [:group_profile_id])
  end
end
