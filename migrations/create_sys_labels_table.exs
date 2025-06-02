defmodule Repo.Migrations.CreateSysLabels do
  use Ecto.Migration

  def change do
    create table(:sys_labels, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :module, :string, null: false
      add :parent, :integer, null: false, default: 0
      add :level, :integer, null: false, default: 0
      add :order, :integer, null: false, default: 0
      add :value, :string, null: false
      timestamps()
    end
    create index(:sys_labels, [:value], unique: true)
  end
end
