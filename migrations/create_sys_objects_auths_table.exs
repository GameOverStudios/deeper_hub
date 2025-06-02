defmodule Repo.Migrations.CreateSysObjectsAuths do
  use Ecto.Migration

  def change do
    create table(:sys_objects_auths, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :ID, :integer, null: false
      add :Name, :string, null: false
      add :Title, :string, null: false
      add :Link, :string, null: false
      add :OnClick, :string, null: false
      add :Icon, :string, null: false
      add :Style, :string, null: false
      timestamps()
    end
  end
end
