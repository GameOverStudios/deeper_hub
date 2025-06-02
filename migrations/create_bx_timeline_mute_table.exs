defmodule Repo.Migrations.CreateBxTimelineMute do
  use Ecto.Migration

  def change do
    create table(:bx_timeline_mute, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :initiator, :integer, null: false
      add :content, :integer, null: false
      add :mutual, :integer, null: false
      add :added, :integer, null: false
      timestamps()
    end
    create index(:bx_timeline_mute, [:initiator])
    create index(:bx_timeline_mute, [:content])
  end
end
