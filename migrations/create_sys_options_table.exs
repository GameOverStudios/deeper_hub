defmodule Repo.Migrations.CreateSysOptions do
  use Ecto.Migration

  def change do
    create table(:sys_options, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :category_id, :integer, null: false, default: 0
      add :name, :string, null: false, default: ""
      add :caption, :string, null: false, default: ""
      add :info, :string, null: false, default: ""
      add :value, :string, null: false
      add :type, :string, null: false, default: "digit"
      add :extra, :string, null: false, default: "''"
      add :check, :string, null: false
      add :check_params, :string, null: false
      add :check_error, :string, null: false, default: ""
      add :order, :integer, default: 0
      timestamps()
    end
    create index(:sys_options, [:category_id])
    create index(:sys_options, [:name], unique: true)
  end
end
