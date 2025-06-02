defmodule Repo.Migrations.CreateSysSearchExtendedFields do
  use Ecto.Migration

  def change do
    create table(:sys_search_extended_fields, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object, :string, null: false, default: ""
      add :name, :string, null: false, default: ""
      add :type, :string, null: false, default: ""
      add :caption, :string, null: false, default: ""
      add :info, :string, null: false, default: ""
      add :values, :string, null: false, default: "''"
      add :pass, :string, null: false
      add :search_type, :string, null: false, default: ""
      add :search_value, :string, null: false, default: ""
      add :search_operator, :string, null: false, default: ""
      add :active, :integer, null: false, default: 0
      add :order, :integer, null: false, default: 0
      timestamps()
    end
    create index(:sys_search_extended_fields, [:object])
  end
end
