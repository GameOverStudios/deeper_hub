defmodule Repo.Migrations.CreateBxFilesDownloadingJobs do
  use Ecto.Migration

  def change do
    create table(:bx_files_downloading_jobs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :owner, :integer, null: false
      add :files, :string, null: false
      add :result, :string, null: false
      add :started, :integer, null: false
      timestamps()
    end
  end
end
