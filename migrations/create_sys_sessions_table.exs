defmodule Repo.Migrations.CreateSysSessions do
  use Ecto.Migration

  def change do
    create table(:sys_sessions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, :integer, null: false, default: 0
      add :data, :string
      add :date, :integer, null: false, default: 0
      timestamps()
    end
    create index(:sys_sessions, [:user_id])
    create index(:sys_sessions, [:date])
  end
end
