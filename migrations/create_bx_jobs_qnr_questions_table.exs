defmodule Repo.Migrations.CreateBxJobsQnrQuestions do
  use Ecto.Migration

  def change do
    create table(:bx_jobs_qnr_questions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :content_id, :integer, null: false, default: 0
      add :added, :integer, null: false, default: 0
      add :action, :string, null: false, default: "add"
      add :question, :string, null: false, default: ""
      add :answer, :string, null: false, default: "text"
      add :extra, :string, null: false
      add :order, :integer, null: false, default: 0
      timestamps()
    end
  end
end
