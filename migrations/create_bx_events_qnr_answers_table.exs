defmodule Repo.Migrations.CreateBxEventsQnrAnswers do
  use Ecto.Migration

  def change do
    create table(:bx_events_qnr_answers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :question_id, :integer, null: false, default: 0
      add :profile_id, :integer, null: false, default: 0
      add :added, :integer, null: false, default: 0
      add :answer, :string, null: false, default: ""
      timestamps()
    end
    create index(:bx_events_qnr_answers, [:question_id])
  end
end
