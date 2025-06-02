defmodule Repo.Migrations.CreateSysBadges do
  use Ecto.Migration

  def change do
    create table(:sys_badges, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :added, :integer, null: false
      add :module, :string, null: false, default: ""
      add :text, :string, null: false, default: ""
      add :icon, :string, null: false, default: "''"
      add :color, :string, null: false, default: ""
      add :fontcolor, :string, null: false, default: ""
      add :is_icon_only, :integer, null: false, default: 1
      timestamps()
    end
  end
end
