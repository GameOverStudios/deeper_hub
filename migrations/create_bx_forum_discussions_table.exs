defmodule Repo.Migrations.CreateBxForumDiscussions do
  use Ecto.Migration

  def change do
    create table(:bx_forum_discussions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :author, :integer, null: false
      add :added, :integer, null: false
      add :changed, :integer, null: false
      add :thumb, :integer, null: false
      add :thumb_data, :string, null: false
      add :title, :string, null: false
      add :cat, :integer, null: false
      add :multicat, :string, null: false
      add :text, :string, null: false
      add :text_comments, :string, null: false
      add :lr_timestamp, :integer, null: false
      add :lr_profile_id, :integer, null: false
      add :lr_comment_id, :integer, null: false
      add :labels, :string, null: false
      add :views, :integer, null: false, default: 0
      add :rate, :float, null: false, default: 0
      add :votes, :integer, null: false, default: 0
      add :rrate, :float, null: false, default: 0
      add :rvotes, :integer, null: false, default: 0
      add :score, :integer, null: false, default: 0
      add :sc_up, :integer, null: false, default: 0
      add :sc_down, :integer, null: false, default: 0
      add :favorites, :integer, null: false, default: 0
      add :comments, :integer, null: false, default: 0
      add :reports, :integer, null: false, default: 0
      add :featured, :integer, null: false, default: 0
      add :stick, :integer, null: false, default: 0
      add :lock, :integer, null: false, default: 0
      add :resolvable, :integer, null: false, default: 0
      add :resolved, :integer, null: false, default: 0
      add :allow_view_to, :string, null: false, default: "3"
      add :cf, :integer, null: false, default: 1
      add :status, :string, null: false, default: "active"
      add :status_admin, :string, null: false, default: "active"
      timestamps()
    end
    create index(:bx_forum_discussions, [:title])
    create index(:bx_forum_discussions, [:lr_timestamp])
  end
end
