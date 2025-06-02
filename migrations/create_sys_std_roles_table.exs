defmodule Repo.Migrations.CreateSysStdRoles do
  use Ecto.Migration

  def change do
    create table(:sys_std_roles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false, default: ""
      add :title, :string, null: false
      add :description, :string, null: false, default: ""
      add :active, :integer, null: false, default: 1
      add :order, :integer, null: false, default: 0
      timestamps()
    end
    create index(:sys_std_roles, [:name], unique: true)
    create index(:sys_std_roles, [:title])
  end
end
