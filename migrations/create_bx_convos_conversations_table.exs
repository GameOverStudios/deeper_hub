defmodule Repo.Migrations.CreateBxConvosConversations do
  use Ecto.Migration

  def change do
    create table(:bx_convos_conversations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :author, :integer, null: false
      add :added, :integer, null: false
      add :changed, :integer, null: false
      add :text, :string, null: false
      add :allow_edit, :integer, null: false, default: 0
      add :views, :integer, null: false, default: 0
      add :comments, :integer, null: false, default: 0
      add :last_reply_timestamp, :integer, null: false
      add :last_reply_profile_id, :integer, null: false
      add :last_reply_comment_id, :integer, null: false
      timestamps()
    end
    create index(:bx_convos_conversations, [:last_reply_timestamp])
  end
end
