defmodule Repo.Migrations.CreateBxFdbAnswers do
  use Ecto.Migration

  def change do
    create table(:bx_fdb_answers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :question_id, :integer, null: false, default: 0
      add :title, :string, null: false
      add :important, :integer, null: false, default: 0
      add :data, :string, null: false, default: "''"
      add :votes, :integer, null: false, default: 0
      add :order, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_fdb_answers, [:title])
  end
end
