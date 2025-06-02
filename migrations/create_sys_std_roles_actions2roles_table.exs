defmodule Repo.Migrations.CreateSysStdRolesActions2roles do
  use Ecto.Migration

  def change do
    create table(:sys_std_roles_actions2roles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :role_id, :integer, null: false, default: 0
      add :action_id, :integer, null: false, default: 0
      timestamps()
    end
  end
end
