defmodule Repo.Migrations.CreateSysBackgroundJobs do
  use Ecto.Migration

  def change do
    create table(:sys_background_jobs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false, default: ""
      add :added, :integer, null: false, default: 0
      add :priority, :integer, null: false, default: 0
      add :service_call, :string, null: false, default: "''"
      add :status, :string, null: false, default: "awaiting"
      timestamps()
    end
    create index(:sys_background_jobs, [:name], unique: true)
  end
end
