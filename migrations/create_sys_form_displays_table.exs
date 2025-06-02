defmodule Repo.Migrations.CreateSysFormDisplays do
  use Ecto.Migration

  def change do
    create table(:sys_form_displays, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :display_name, :string, null: false
      add :module, :string, null: false
      add :object, :string, null: false
      add :title, :string, null: false
      add :view_mode, :integer, null: false, default: 0
      timestamps()
    end
    create index(:sys_form_displays, [:object])
  end
end
