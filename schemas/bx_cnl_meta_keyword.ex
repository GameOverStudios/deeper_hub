defmodule DeeperHub.Schema.BxCnlMetaKeyword do
  @moduledoc """
  Schema para representação de bx_cnl_meta_keywords no sistema

  Este schema armazena as informações de um bx_cnl_meta_keyword.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_cnl_meta_keywords" do
    field :object_id, :integer  # int(10) unsigned
    field :keyword, :string  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_cnl_meta_keyword no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object_id: integer() | nil,
    keyword: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_cnl_meta_keyword.

  ## Parâmetros 
    - `bx_cnl_meta_keyword`: Struct do bx_cnl_meta_keyword (pode ser %BxCnlMetaKeyword{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_cnl_meta_keyword \ %__MODULE__{}, attrs) do
    bx_cnl_meta_keyword
    |> cast(attrs, [:object_id, :keyword])
    |> validate_required([:object_id, :keyword])
  end

  @doc """
  Changeset para atualização de um bx_cnl_meta_keyword existente.

  ## Parâmetros 
    - `bx_cnl_meta_keyword`: Struct do bx_cnl_meta_keyword (%BxCnlMetaKeyword{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_cnl_meta_keyword \ %__MODULE__{}, attrs) do
    bx_cnl_meta_keyword
    |> cast(attrs, [:object_id, :keyword])
  end
end
