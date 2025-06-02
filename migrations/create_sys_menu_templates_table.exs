defmodule Repo.Migrations.CreateSysMenuTemplates do
  use Ecto.Migration

  def change do
    create table(:sys_menu_templates, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :template, :string, null: false
      add :title, :string, null: false
      add :visible, :integer, null: false, default: 1
      timestamps()
    end
  end
end
