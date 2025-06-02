defmodule Repo.Migrations.CreateBxPostsCmts do
  use Ecto.Migration

  def change do
    create table(:bx_posts_cmts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :cmt_id, :integer, null: false
      add :cmt_parent_id, :integer, null: false, default: 0
      add :cmt_vparent_id, :integer, null: false, default: 0
      add :cmt_object_id, :integer, null: false, default: 0
      add :cmt_author_id, :integer, null: false, default: 0
      add :cmt_level, :integer, null: false, default: 0
      add :cmt_text, :string, null: false
      add :cmt_mood, :integer, null: false, default: 0
      add :cmt_rate, :integer, null: false, default: 0
      add :cmt_rate_count, :integer, null: false, default: 0
      add :cmt_time, :integer, null: false, default: 0
      add :cmt_replies, :integer, null: false, default: 0
      add :cmt_pinned, :integer, null: false, default: 0
      add :cmt_cf, :integer, null: false, default: 1
      timestamps()
    end
    create index(:bx_posts_cmts, [:cmt_object_id])
    create index(:bx_posts_cmts, [:cmt_text])
  end
end
