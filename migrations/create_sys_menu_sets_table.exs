defmodule Repo.Migrations.CreateSysMenuSets do
  use Ecto.Migration

  def change do
    create table(:sys_menu_sets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :set_name, :string, null: false
      add :module, :string, null: false
      add :title, :string, null: false
      add :deletable, :integer, null: false, default: 1
      timestamps()
    end
  end
end
