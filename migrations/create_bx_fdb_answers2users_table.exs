defmodule Repo.Migrations.CreateBxFdbAnswers2users do
  use Ecto.Migration

  def change do
    create table(:bx_fdb_answers2users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :answer_id, :integer, null: false, default: 0
      add :profile_id, :integer, null: false, default: 0
      add :text, :string, null: false, default: ""
      add :added, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_fdb_answers2users, [:answer_id])
  end
end
