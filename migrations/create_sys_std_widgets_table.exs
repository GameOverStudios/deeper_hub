defmodule Repo.Migrations.CreateSysStdWidgets do
  use Ecto.Migration

  def change do
    create table(:sys_std_widgets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :page_id, :string, null: false, default: ""
      add :module, :string, null: false, default: ""
      add :type, :string, null: false, default: ""
      add :url, :string, null: false, default: ""
      add :click, :string, null: false, default: "''"
      add :icon, :string, null: false, default: ""
      add :caption, :string, null: false, default: ""
      add :cnt_notices, :string, null: false, default: "''"
      add :cnt_actions, :string, null: false, default: "''"
      add :featured, :integer, null: false, default: 0
      timestamps()
    end
  end
end
