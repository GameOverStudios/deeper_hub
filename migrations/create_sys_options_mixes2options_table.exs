defmodule Repo.Migrations.CreateSysOptionsMixes2options do
  use Ecto.Migration

  def change do
    create table(:sys_options_mixes2options, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :option, :string, null: false, default: ""
      add :mix_id, :integer, null: false, default: 0
      add :value, :string, null: false
      timestamps()
    end
    create index(:sys_options_mixes2options, [:option])
  end
end
