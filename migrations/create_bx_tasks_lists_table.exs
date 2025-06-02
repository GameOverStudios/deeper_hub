defmodule Repo.Migrations.CreateBxTasksLists do
  use Ecto.Migration

  def change do
    create table(:bx_tasks_lists, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :context_id, :integer, null: false
      add :title, :string, null: false
      timestamps()
    end
  end
end
