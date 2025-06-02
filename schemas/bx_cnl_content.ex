defmodule DeeperHub.Schema.BxCnlContent do
  @moduledoc """
  Schema para representação de bx_cnl_contents no sistema

  Este schema armazena as informações de um bx_cnl_content.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_cnl_content" do
    field :content_id, :integer  # int(11)
    field :cnl_id, :integer  # int(11)
    field :author_id, :integer  # int(11)
    field :module_name, :string  # varchar(19)
    field :date, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_cnl_content no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    content_id: integer() | nil,
    cnl_id: integer() | nil,
    author_id: integer() | nil,
    module_name: String.t() | nil,
    date: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_cnl_content.

  ## Parâmetros 
    - `bx_cnl_content`: Struct do bx_cnl_content (pode ser %BxCnlContent{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_cnl_content \ %__MODULE__{}, attrs) do
    bx_cnl_content
    |> cast(attrs, [:content_id, :cnl_id, :author_id, :module_name, :date])
    |> validate_required([:content_id, :cnl_id, :author_id, :module_name])
  end

  @doc """
  Changeset para atualização de um bx_cnl_content existente.

  ## Parâmetros 
    - `bx_cnl_content`: Struct do bx_cnl_content (%BxCnlContent{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_cnl_content \ %__MODULE__{}, attrs) do
    bx_cnl_content
    |> cast(attrs, [:content_id, :cnl_id, :author_id, :module_name, :date])
  end
end
