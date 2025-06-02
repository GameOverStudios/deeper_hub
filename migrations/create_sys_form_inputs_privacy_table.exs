defmodule Repo.Migrations.CreateSysFormInputsPrivacy do
  use Ecto.Migration

  def change do
    create table(:sys_form_inputs_privacy, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :input_id, :integer, null: false, default: 0
      add :author_id, :integer, null: false, default: 0
      add :allow_view_to, :string, null: false, default: "3"
      timestamps()
    end
    create index(:sys_form_inputs_privacy, [:input_id])
  end
end
