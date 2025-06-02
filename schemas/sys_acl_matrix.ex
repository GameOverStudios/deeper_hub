defmodule DeeperHub.Schema.SysAclMatrix do
  @moduledoc """
  Schema para representação de sys_acl_matrixs no sistema

  Este schema armazena as informações de um sys_acl_matrix.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_acl_matrix" do
    field :IDLevel, :integer, default: 0  # int(10) unsigned
    field :IDAction, :integer, default: 0  # int(10) unsigned
    field :AllowedCount, :integer  # int(10) unsigned
    field :AllowedPeriodLen, :integer  # int(10) unsigned
    field :AllowedPeriodStart, :naive_datetime  # datetime
    field :AllowedPeriodEnd, :naive_datetime  # datetime
    field :AdditionalParamValue, :string  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_acl_matrix no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    IDLevel: integer() | nil,
    IDAction: integer() | nil,
    AllowedCount: integer() | nil,
    AllowedPeriodLen: integer() | nil,
    AllowedPeriodStart: NaiveDateTime.t() | nil,
    AllowedPeriodEnd: NaiveDateTime.t() | nil,
    AdditionalParamValue: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_acl_matrix.

  ## Parâmetros 
    - `sys_acl_matrix`: Struct do sys_acl_matrix (pode ser %SysAclMatrix{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_acl_matrix \ %__MODULE__{}, attrs) do
    sys_acl_matrix
    |> cast(attrs, [:IDLevel, :IDAction, :AllowedCount, :AllowedPeriodLen, :AllowedPeriodStart, :AllowedPeriodEnd, :AdditionalParamValue])
  end

  @doc """
  Changeset para atualização de um sys_acl_matrix existente.

  ## Parâmetros 
    - `sys_acl_matrix`: Struct do sys_acl_matrix (%SysAclMatrix{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_acl_matrix \ %__MODULE__{}, attrs) do
    sys_acl_matrix
    |> cast(attrs, [:IDLevel, :IDAction, :AllowedCount, :AllowedPeriodLen, :AllowedPeriodStart, :AllowedPeriodEnd, :AdditionalParamValue])
  end
end
