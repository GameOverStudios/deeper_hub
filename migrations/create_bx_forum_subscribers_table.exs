defmodule Repo.Migrations.CreateBxForumSubscribers do
  use Ecto.Migration

  def change do
    create table(:bx_forum_subscribers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :initiator, :integer, null: false
      add :content, :integer, null: false
      add :added, :integer, null: false
      timestamps()
    end
    create index(:bx_forum_subscribers, [:initiator])
    create index(:bx_forum_subscribers, [:content])
  end
end
