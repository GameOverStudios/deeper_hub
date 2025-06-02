defmodule Repo.Migrations.CreateSysStdRolesActions do
  use Ecto.Migration

  def change do
    create table(:sys_std_roles_actions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false, default: ""
      add :title, :string, null: false
      add :description, :string, null: false
      timestamps()
    end
    create index(:sys_std_roles_actions, [:title])
  end
end
