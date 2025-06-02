defmodule Repo.Migrations.CreateSysQueuePush do
  use Ecto.Migration

  def change do
    create table(:sys_queue_push, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :profile_id, :integer, null: false, default: 0
      add :message, :string, null: false, default: "''"
      timestamps()
    end
  end
end
