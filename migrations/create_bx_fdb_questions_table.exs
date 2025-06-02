defmodule Repo.Migrations.CreateBxFdbQuestions do
  use Ecto.Migration

  def change do
    create table(:bx_fdb_questions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :author, :integer, null: false
      add :added, :integer, null: false, default: 0
      add :changed, :integer, null: false, default: 0
      add :text, :string, null: false
      add :lifetime, :integer, null: false, default: 0
      add :allow_view_to, :string, null: false, default: "3"
      add :status_admin, :string, null: false, default: "active"
      timestamps()
    end
    create index(:bx_fdb_questions, [:text])
  end
end
