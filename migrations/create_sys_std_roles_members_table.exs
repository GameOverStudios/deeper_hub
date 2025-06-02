defmodule Repo.Migrations.CreateSysStdRolesMembers do
  use Ecto.Migration

  def change do
    create table(:sys_std_roles_members, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, :integer, null: false, default: 0
      add :role, :integer, null: false, default: 0
      timestamps()
    end
    create index(:sys_std_roles_members, [:account_id], unique: true)
  end
end
