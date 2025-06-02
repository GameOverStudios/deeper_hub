defmodule Repo.Migrations.CreateSysObjectsPayments do
  use Ecto.Migration

  def change do
    create table(:sys_objects_payments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object, :string, null: false
      add :title, :string, null: false
      add :uri, :string, null: false, default: ""
      timestamps()
    end
    create index(:sys_objects_payments, [:object], unique: true)
    create index(:sys_objects_payments, [:uri], unique: true)
  end
end
