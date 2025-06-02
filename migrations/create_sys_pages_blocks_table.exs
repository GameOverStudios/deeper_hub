defmodule Repo.Migrations.CreateSysPagesBlocks do
  use Ecto.Migration

  def change do
    create table(:sys_pages_blocks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object, :string, null: false
      add :cell_id, :integer, null: false, default: 1
      add :module, :string, null: false
      add :title_system, :string, null: false
      add :title, :string, null: false
      add :designbox_id, :integer, null: false, default: 11
      add :class, :string, null: false, default: ""
      add :submenu, :string, null: false, default: ""
      add :tabs, :integer, null: false, default: 0
      add :async, :integer, null: false, default: 0
      add :visible_for_levels, :integer, null: false, default: 2147483647
      add :hidden_on, :string, null: false, default: ""
      add :type, :string, null: false, default: "raw"
      add :content, :string, null: false
      add :content_empty, :string, null: false, default: ""
      add :text, :string, null: false
      add :text_updated, :integer, null: false
      add :help, :string, null: false
      add :cache_lifetime, :integer, null: false, default: 0
      add :config_api, :string, null: false
      add :deletable, :integer, null: false, default: 1
      add :copyable, :integer, null: false, default: 1
      add :active, :integer, null: false, default: 1
      add :active_api, :integer, null: false, default: 0
      add :order, :integer, null: false
      timestamps()
    end
    create index(:sys_pages_blocks, [:object])
    create index(:sys_pages_blocks, [:text])
  end
end
