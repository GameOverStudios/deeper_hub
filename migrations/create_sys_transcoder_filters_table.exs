defmodule Repo.Migrations.CreateSysTranscoderFilters do
  use Ecto.Migration

  def change do
    create table(:sys_transcoder_filters, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :transcoder_object, :string, null: false
      add :filter, :string, null: false
      add :filter_params, :string, null: false
      add :order, :integer, null: false, default: 0
      timestamps()
    end
    create index(:sys_transcoder_filters, [:transcoder_object])
  end
end
