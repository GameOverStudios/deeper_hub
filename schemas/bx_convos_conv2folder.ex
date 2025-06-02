defmodule DeeperHub.Schema.BxConvosConv2folder do
  @moduledoc """
  Schema para representação de bx_convos_conv2folders no sistema

  Este schema armazena as informações de um bx_convos_conv2folder.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_convos_conv2folder" do
    field :conv_id, :integer  # int(10) unsigned
    field :folder_id, :integer  # int(10) unsigned
    field :collaborator, :integer  # int(10) unsigned
    field :read_comments, :integer, default: -1  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_convos_conv2folder no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    conv_id: integer() | nil,
    folder_id: integer() | nil,
    collaborator: integer() | nil,
    read_comments: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_convos_conv2folder.

  ## Parâmetros 
    - `bx_convos_conv2folder`: Struct do bx_convos_conv2folder (pode ser %BxConvosConv2folder{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_convos_conv2folder \ %__MODULE__{}, attrs) do
    bx_convos_conv2folder
    |> cast(attrs, [:conv_id, :folder_id, :collaborator, :read_comments])
    |> validate_required([:conv_id, :folder_id, :collaborator])
  end

  @doc """
  Changeset para atualização de um bx_convos_conv2folder existente.

  ## Parâmetros 
    - `bx_convos_conv2folder`: Struct do bx_convos_conv2folder (%BxConvosConv2folder{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_convos_conv2folder \ %__MODULE__{}, attrs) do
    bx_convos_conv2folder
    |> cast(attrs, [:conv_id, :folder_id, :collaborator, :read_comments])
  end
end
