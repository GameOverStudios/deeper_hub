defmodule Repo.Migrations.CreateSysTranscoderQueue do
  use Ecto.Migration

  def change do
    create table(:sys_transcoder_queue, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :transcoder_object, :string, null: false
      add :profile_id, :integer, null: false
      add :file_url_source, :string, null: false
      add :file_id_source, :string, null: false
      add :file_url_result, :string, null: false
      add :file_ext_result, :string, null: false
      add :file_id_result, :integer, null: false
      add :server, :string, null: false
      add :status, :string, null: false
      add :pid, :integer, null: false, default: 0
      add :added, :integer, null: false
      add :changed, :integer, null: false
      add :log, :string, null: false
      timestamps()
    end
    create index(:sys_transcoder_queue, [:transcoder_object])
  end
end
