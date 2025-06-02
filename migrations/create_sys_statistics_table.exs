defmodule Repo.Migrations.CreateSysStatistics do
  use Ecto.Migration

  def change do
    create table(:sys_statistics, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :module, :string, null: false, default: ""
      add :name, :string, null: false, default: ""
      add :title, :string, null: false, default: ""
      add :link, :string, null: false, default: ""
      add :icon, :string, null: false, default: ""
      add :query, :string, null: false, default: "''"
      add :order, :integer, null: false, default: 0
      timestamps()
    end
    create index(:sys_statistics, [:name], unique: true)
  end
end
