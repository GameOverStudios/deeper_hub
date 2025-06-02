defmodule Repo.Migrations.CreateSysCronJobs do
  use Ecto.Migration

  def change do
    create table(:sys_cron_jobs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false, default: ""
      add :time, :string, null: false, default: "*"
      add :class, :string, null: false, default: ""
      add :file, :string, null: false, default: ""
      add :service_call, :string, null: false, default: "''"
      add :ts, :integer, null: false
      add :timing, :float, null: false
      timestamps()
    end
  end
end
