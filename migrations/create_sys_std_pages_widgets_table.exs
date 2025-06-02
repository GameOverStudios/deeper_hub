defmodule Repo.Migrations.CreateSysStdPagesWidgets do
  use Ecto.Migration

  def change do
    create table(:sys_std_pages_widgets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :page_id, :integer, null: false, default: 0
      add :widget_id, :integer, null: false, default: 0
      add :order, :integer, null: false, default: 0
      timestamps()
    end
    create index(:sys_std_pages_widgets, [:widget_id])
  end
end
