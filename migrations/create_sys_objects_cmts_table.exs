defmodule Repo.Migrations.CreateSysObjectsCmts do
  use Ecto.Migration

  def change do
    create table(:sys_objects_cmts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :ID, :integer, null: false
      add :Name, :string, null: false
      add :Module, :string, null: false
      add :Table, :string, null: false
      add :CharsPostMin, :integer, null: false
      add :CharsPostMax, :integer, null: false
      add :CharsDisplayMax, :integer, null: false
      add :Html, :integer, null: false
      add :PerView, :integer, null: false
      add :PerViewReplies, :integer, null: false
      add :BrowseType, :string, null: false
      add :IsBrowseSwitch, :integer, null: false
      add :PostFormPosition, :string, null: false
      add :NumberOfLevels, :integer, null: false
      add :IsDisplaySwitch, :integer, null: false
      add :IsRatable, :integer, null: false
      add :ViewingThreshold, :integer, null: false
      add :IsOn, :integer, null: false
      add :RootStylePrefix, :string, null: false, default: "cmt"
      add :BaseUrl, :string, null: false
      add :ObjectVote, :string, null: false, default: ""
      add :ObjectReaction, :string, null: false, default: ""
      add :ObjectScore, :string, null: false, default: ""
      add :ObjectReport, :string, null: false, default: ""
      add :TriggerTable, :string, null: false
      add :TriggerFieldId, :string, null: false
      add :TriggerFieldAuthor, :string, null: false
      add :TriggerFieldTitle, :string, null: false
      add :TriggerFieldComments, :string, null: false
      add :ClassName, :string, null: false
      add :ClassFile, :string, null: false
      timestamps()
    end
  end
end
