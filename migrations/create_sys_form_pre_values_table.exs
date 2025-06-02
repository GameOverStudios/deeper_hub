defmodule Repo.Migrations.CreateSysFormPreValues do
  use Ecto.Migration

  def change do
    create table(:sys_form_pre_values, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :Key, :string, null: false, default: ""
      add :Value, :string, null: false, default: ""
      add :Order, :integer, null: false, default: 0
      add :LKey, :string, null: false, default: ""
      add :LKey2, :string, null: false, default: ""
      add :Data, :string, null: false, default: "''"
      timestamps()
    end
    create index(:sys_form_pre_values, [:Key])
  end
end
