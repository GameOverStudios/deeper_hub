defmodule DeeperHub.Schema.SysObjectsCmt do
  @moduledoc """
  Schema para representação de sys_objects_cmts no sistema

  Este schema armazena as informações de um sys_objects_cmt.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_objects_cmts" do
    field :ID, :integer  # int(10) unsigned
    field :Name, :string  # varchar(64)
    field :Module, :string  # varchar(32)
    field :Table, :string  # varchar(50)
    field :CharsPostMin, :integer  # int(10)
    field :CharsPostMax, :integer  # int(10)
    field :CharsDisplayMax, :integer  # int(10)
    field :Html, :integer  # smallint(1)
    field :PerView, :integer  # smallint(6)
    field :PerViewReplies, :integer  # smallint(6)
    field :BrowseType, :string  # varchar(50)
    field :IsBrowseSwitch, :integer  # smallint(1)
    field :PostFormPosition, :string  # varchar(50)
    field :NumberOfLevels, :integer  # smallint(6)
    field :IsDisplaySwitch, :integer  # smallint(1)
    field :IsRatable, :integer  # smallint(1)
    field :ViewingThreshold, :integer  # smallint(6)
    field :IsOn, :integer  # smallint(1)
    field :RootStylePrefix, :string, default: "cmt"  # varchar(16)
    field :BaseUrl, :string  # varchar(256)
    field :ObjectVote, :string, default: ""  # varchar(64)
    field :ObjectReaction, :string, default: ""  # varchar(64)
    field :ObjectScore, :string, default: ""  # varchar(64)
    field :ObjectReport, :string, default: ""  # varchar(64)
    field :TriggerTable, :string  # varchar(32)
    field :TriggerFieldId, :string  # varchar(32)
    field :TriggerFieldAuthor, :string  # varchar(32)
    field :TriggerFieldTitle, :string  # varchar(32)
    field :TriggerFieldComments, :string  # varchar(32)
    field :ClassName, :string  # varchar(32)
    field :ClassFile, :string  # varchar(256)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_objects_cmt no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    ID: integer() | nil,
    Name: String.t() | nil,
    Module: String.t() | nil,
    Table: String.t() | nil,
    CharsPostMin: integer() | nil,
    CharsPostMax: integer() | nil,
    CharsDisplayMax: integer() | nil,
    Html: integer() | nil,
    PerView: integer() | nil,
    PerViewReplies: integer() | nil,
    BrowseType: String.t() | nil,
    IsBrowseSwitch: integer() | nil,
    PostFormPosition: String.t() | nil,
    NumberOfLevels: integer() | nil,
    IsDisplaySwitch: integer() | nil,
    IsRatable: integer() | nil,
    ViewingThreshold: integer() | nil,
    IsOn: integer() | nil,
    RootStylePrefix: String.t() | nil,
    BaseUrl: String.t() | nil,
    ObjectVote: String.t() | nil,
    ObjectReaction: String.t() | nil,
    ObjectScore: String.t() | nil,
    ObjectReport: String.t() | nil,
    TriggerTable: String.t() | nil,
    TriggerFieldId: String.t() | nil,
    TriggerFieldAuthor: String.t() | nil,
    TriggerFieldTitle: String.t() | nil,
    TriggerFieldComments: String.t() | nil,
    ClassName: String.t() | nil,
    ClassFile: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_objects_cmt.

  ## Parâmetros 
    - `sys_objects_cmt`: Struct do sys_objects_cmt (pode ser %SysObjectsCmt{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_objects_cmt \ %__MODULE__{}, attrs) do
    sys_objects_cmt
    |> cast(attrs, [:ID, :Name, :Module, :Table, :CharsPostMin, :CharsPostMax, :CharsDisplayMax, :Html, :PerView, :PerViewReplies, :BrowseType, :IsBrowseSwitch, :PostFormPosition, :NumberOfLevels, :IsDisplaySwitch, :IsRatable, :ViewingThreshold, :IsOn, :RootStylePrefix, :BaseUrl, :ObjectVote, :ObjectReaction, :ObjectScore, :ObjectReport, :TriggerTable, :TriggerFieldId, :TriggerFieldAuthor, :TriggerFieldTitle, :TriggerFieldComments, :ClassName, :ClassFile])
    |> validate_required([:ID, :Name, :Module, :Table, :CharsPostMin, :CharsPostMax, :CharsDisplayMax, :Html, :PerView, :PerViewReplies, :BrowseType, :IsBrowseSwitch, :PostFormPosition, :NumberOfLevels, :IsDisplaySwitch, :IsRatable, :ViewingThreshold, :IsOn, :BaseUrl, :ObjectVote, :ObjectReaction, :ObjectScore, :ObjectReport, :TriggerTable, :TriggerFieldId, :TriggerFieldAuthor, :TriggerFieldTitle, :TriggerFieldComments, :ClassName, :ClassFile])
  end

  @doc """
  Changeset para atualização de um sys_objects_cmt existente.

  ## Parâmetros 
    - `sys_objects_cmt`: Struct do sys_objects_cmt (%SysObjectsCmt{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_objects_cmt \ %__MODULE__{}, attrs) do
    sys_objects_cmt
    |> cast(attrs, [:ID, :Name, :Module, :Table, :CharsPostMin, :CharsPostMax, :CharsDisplayMax, :Html, :PerView, :PerViewReplies, :BrowseType, :IsBrowseSwitch, :PostFormPosition, :NumberOfLevels, :IsDisplaySwitch, :IsRatable, :ViewingThreshold, :IsOn, :RootStylePrefix, :BaseUrl, :ObjectVote, :ObjectReaction, :ObjectScore, :ObjectReport, :TriggerTable, :TriggerFieldId, :TriggerFieldAuthor, :TriggerFieldTitle, :TriggerFieldComments, :ClassName, :ClassFile])
  end
end
