defmodule Repo.Migrations.CreateSysFormPreLists do
  use Ecto.Migration

  def change do
    create table(:sys_form_pre_lists, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :module, :string, null: false, default: ""
      add :key, :string, null: false, default: ""
      add :title, :string, null: false, default: ""
      add :use_for_sets, :integer, null: false, default: 1
      add :extendable, :integer, null: false, default: 1
      timestamps()
    end
    create index(:sys_form_pre_lists, [:module])
    create index(:sys_form_pre_lists, [:key], unique: true)
  end
end
