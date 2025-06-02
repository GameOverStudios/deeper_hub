defmodule Repo.Migrations.CreateSysAclMatrix do
  use Ecto.Migration

  def change do
    create table(:sys_acl_matrix, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :IDLevel, :integer, null: false, default: 0
      add :IDAction, :integer, null: false, default: 0
      add :AllowedCount, :integer
      add :AllowedPeriodLen, :integer
      add :AllowedPeriodStart, :naive_datetime
      add :AllowedPeriodEnd, :naive_datetime
      add :AdditionalParamValue, :string
      timestamps()
    end
  end
end
