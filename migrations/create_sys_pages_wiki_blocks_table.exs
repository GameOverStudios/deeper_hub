defmodule Repo.Migrations.CreateSysPagesWikiBlocks do
  use Ecto.Migration

  def change do
    create table(:sys_pages_wiki_blocks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :block_id, :integer, null: false
      add :revision, :integer, null: false
      add :language, :string, null: false
      add :main_lang, :integer, null: false, default: 0
      add :profile_id, :integer, null: false
      add :content, :string, null: false
      add :unsafe, :integer, null: false, default: 0
      add :notes, :string, null: false
      add :added, :integer, null: false
      timestamps()
    end
    create index(:sys_pages_wiki_blocks, [:block_id])
  end
end
