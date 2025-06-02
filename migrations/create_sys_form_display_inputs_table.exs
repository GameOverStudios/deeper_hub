defmodule Repo.Migrations.CreateSysFormDisplayInputs do
  use Ecto.Migration

  def change do
    create table(:sys_form_display_inputs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :display_name, :string, null: false
      add :input_name, :string, null: false
      add :visible_for_levels, :integer, null: false, default: 2147483647
      add :active, :integer, null: false, default: 0
      add :order, :integer, null: false
      timestamps()
    end
    create index(:sys_form_display_inputs, [:display_name])
  end
end
