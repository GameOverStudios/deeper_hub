defmodule Repo.Migrations.CreateSysFormFieldsIds do
  use Ecto.Migration

  def change do
    create table(:sys_form_fields_ids, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object_form, :string, null: false, default: ""
      add :module, :string, null: false
      add :field_name, :string, null: false, default: ""
      add :content_id, :integer, null: false, default: 0
      add :author_id, :integer, null: false, default: 0
      add :nested_content_id, :integer, null: false, default: 0
      add :rate, :float, null: false, default: 0
      add :votes, :integer, null: false, default: 0
      add :rrate, :float, null: false, default: 0
      add :rvotes, :integer, null: false, default: 0
      timestamps()
    end
    create index(:sys_form_fields_ids, [:object_form])
  end
end
