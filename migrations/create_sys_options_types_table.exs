defmodule Repo.Migrations.CreateSysOptionsTypes do
  use Ecto.Migration

  def change do
    create table(:sys_options_types, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :group, :string, null: false, default: ""
      add :name, :string, null: false, default: ""
      add :caption, :string, null: false, default: ""
      add :icon, :string, null: false, default: ""
      add :order, :integer, default: 0
      timestamps()
    end
    create index(:sys_options_types, [:name], unique: true)
  end
end
