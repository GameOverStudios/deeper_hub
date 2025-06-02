defmodule DeeperHub.Schema.SysCmtsMetaKeyword do
  @moduledoc """
  Schema para representação de sys_cmts_meta_keywords no sistema

  Este schema armazena as informações de um sys_cmts_meta_keyword.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_cmts_meta_keywords" do
    field :object_id, :integer  # int(10) unsigned
    field :keyword, :string  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_cmts_meta_keyword no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object_id: integer() | nil,
    keyword: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_cmts_meta_keyword.

  ## Parâmetros 
    - `sys_cmts_meta_keyword`: Struct do sys_cmts_meta_keyword (pode ser %SysCmtsMetaKeyword{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_cmts_meta_keyword \ %__MODULE__{}, attrs) do
    sys_cmts_meta_keyword
    |> cast(attrs, [:object_id, :keyword])
    |> validate_required([:object_id, :keyword])
  end

  @doc """
  Changeset para atualização de um sys_cmts_meta_keyword existente.

  ## Parâmetros 
    - `sys_cmts_meta_keyword`: Struct do sys_cmts_meta_keyword (%SysCmtsMetaKeyword{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_cmts_meta_keyword \ %__MODULE__{}, attrs) do
    sys_cmts_meta_keyword
    |> cast(attrs, [:object_id, :keyword])
  end
end
