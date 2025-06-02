defmodule Repo.Migrations.CreateBxPostsPollsAnswers do
  use Ecto.Migration

  def change do
    create table(:bx_posts_polls_answers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :poll_id, :integer, null: false, default: 0
      add :title, :string, null: false
      add :rate, :float, null: false, default: 0
      add :votes, :integer, null: false, default: 0
      add :order, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_posts_polls_answers, [:poll_id])
    create index(:bx_posts_polls_answers, [:title])
  end
end
