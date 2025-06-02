defmodule Repo.Migrations.CreateSysStdWidgetsBookmarks do
  use Ecto.Migration

  def change do
    create table(:sys_std_widgets_bookmarks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :widget_id, :integer, null: false, default: 0
      add :profile_id, :integer, null: false, default: 0
      add :bookmark, :integer, null: false, default: 0
      timestamps()
    end
    create index(:sys_std_widgets_bookmarks, [:widget_id])
  end
end
