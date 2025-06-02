defmodule Repo.Migrations.CreateSysSearchExtendedSortingFields do
  use Ecto.Migration

  def change do
    create table(:sys_search_extended_sorting_fields, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object, :string, null: false, default: ""
      add :name, :string, null: false, default: ""
      add :direction, :string, null: false, default: ""
      add :caption, :string, null: false, default: ""
      add :active, :integer, null: false, default: 0
      add :order, :integer, null: false, default: 0
      timestamps()
    end
    create index(:sys_search_extended_sorting_fields, [:object])
  end
end
