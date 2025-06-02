defmodule DeeperHub.Schema.BxConvosFolder do
  @moduledoc """
  Schema para representação de bx_convos_folders no sistema

  Este schema armazena as informações de um bx_convos_folder.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_convos_folders" do
    field :author, :integer  # int(10) unsigned
    field :name, :string, default: ""  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_convos_folder no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    author: integer() | nil,
    name: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_convos_folder.

  ## Parâmetros 
    - `bx_convos_folder`: Struct do bx_convos_folder (pode ser %BxConvosFolder{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_convos_folder \ %__MODULE__{}, attrs) do
    bx_convos_folder
    |> cast(attrs, [:author, :name])
    |> validate_required([:author, :name])
  end

  @doc """
  Changeset para atualização de um bx_convos_folder existente.

  ## Parâmetros 
    - `bx_convos_folder`: Struct do bx_convos_folder (%BxConvosFolder{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_convos_folder \ %__MODULE__{}, attrs) do
    bx_convos_folder
    |> cast(attrs, [:author, :name])
  end
end
