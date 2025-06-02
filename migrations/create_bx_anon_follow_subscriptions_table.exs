defmodule Repo.Migrations.CreateBxAnonFollowSubscriptions do
  use Ecto.Migration

  def change do
    create table(:bx_anon_follow_subscriptions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :initiator, :integer, null: false
      add :content, :integer, null: false
      add :added, :integer, null: false
      timestamps()
    end
    create index(:bx_anon_follow_subscriptions, [:initiator])
    create index(:bx_anon_follow_subscriptions, [:content])
  end
end
