defmodule Repo.Migrations.CreateSysAudit do
  use Ecto.Migration

  def change do
    create table(:sys_audit, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :added, :integer, null: false
      add :profile_id, :integer, null: false
      add :profile_title, :string, null: false
      add :content_id, :integer, null: false
      add :content_title, :string, null: false
      add :content_module, :string, null: false, default: ""
      add :content_info_object, :string, null: false, default: ""
      add :context_profile_id, :integer, null: false
      add :context_profile_title, :string, null: false
      add :action_lang_key, :string, null: false
      add :action_lang_key_params, :string, null: false
      add :extras, :string, null: false
      timestamps()
    end
  end
end
