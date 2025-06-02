defmodule Repo.Migrations.CreateSysGridActions do
  use Ecto.Migration

  def change do
    create table(:sys_grid_actions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object, :string, null: false
      add :type, :string, null: false
      add :name, :string, null: false
      add :title, :string, null: false
      add :icon, :string, null: false
      add :icon_only, :integer, null: false, default: 0
      add :confirm, :integer, null: false, default: 1
      add :active, :integer, null: false, default: 1
      add :order, :integer, null: false
      timestamps()
    end
    create index(:sys_grid_actions, [:object])
  end
end
