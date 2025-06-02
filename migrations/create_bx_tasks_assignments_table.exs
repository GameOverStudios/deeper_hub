defmodule Repo.Migrations.CreateBxTasksAssignments do
  use Ecto.Migration

  def change do
    create table(:bx_tasks_assignments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :initiator, :integer, null: false
      add :content, :integer, null: false
      add :added, :integer, null: false
      timestamps()
    end
    create index(:bx_tasks_assignments, [:initiator])
    create index(:bx_tasks_assignments, [:content])
  end
end
