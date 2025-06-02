defmodule Repo.Migrations.CreateSysFormInputs do
  use Ecto.Migration

  def change do
    create table(:sys_form_inputs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object, :string, null: false
      add :module, :string, null: false
      add :name, :string, null: false
      add :value, :string, null: false
      add :values, :string, null: false
      add :checked, :integer, null: false, default: 0
      add :type, :string, null: false
      add :caption_system, :string, null: false
      add :caption, :string, null: false
      add :info, :string, null: false
      add :help, :string, null: false
      add :icon, :string, null: false
      add :required, :integer, null: false, default: 0
      add :unique, :integer, null: false, default: 0
      add :collapsed, :integer, null: false, default: 0
      add :html, :integer, null: false, default: 0
      add :privacy, :integer, null: false, default: 0
      add :rateable, :string, null: false, default: ""
      add :attrs, :string, null: false
      add :attrs_tr, :string, null: false
      add :attrs_wrapper, :string, null: false
      add :checker_func, :string, null: false
      add :checker_params, :string, null: false
      add :checker_error, :string, null: false
      add :db_pass, :string, null: false
      add :db_params, :string, null: false
      add :editable, :integer, null: false, default: 1
      add :deletable, :integer, null: false, default: 1
      timestamps()
    end
    create index(:sys_form_inputs, [:object])
  end
end
