defmodule Repo.Migrations.CreateSysQueueEmail do
  use Ecto.Migration

  def change do
    create table(:sys_queue_email, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false, default: ""
      add :subject, :string, null: false, default: ""
      add :body, :string, null: false, default: "''"
      add :params, :string, null: false, default: "''"
      timestamps()
    end
  end
end
