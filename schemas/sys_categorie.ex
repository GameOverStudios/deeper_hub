defmodule DeeperHub.Schema.SysCategorie do
  @moduledoc """
  Schema para representação de sys_categories no sistema

  Este schema armazena as informações de um sys_categorie.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_categories" do
    field :author, :integer  # int(11)
    field :added, :integer  # int(11)
    field :module, :string  # varchar(32)
    field :value, :string  # varchar(100)
    field :status, Ecto.Enum, values: [:active, :hidden], default: "active"  # enum('active','hidden')

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_categorie no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    author: integer() | nil,
    added: integer() | nil,
    module: String.t() | nil,
    value: String.t() | nil,
    status: :active | :hidden | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_categorie.

  ## Parâmetros 
    - `sys_categorie`: Struct do sys_categorie (pode ser %SysCategorie{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_categorie \ %__MODULE__{}, attrs) do
    sys_categorie
    |> cast(attrs, [:author, :added, :module, :value, :status])
    |> validate_required([:author, :added, :module, :value])
  end

  @doc """
  Changeset para atualização de um sys_categorie existente.

  ## Parâmetros 
    - `sys_categorie`: Struct do sys_categorie (%SysCategorie{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_categorie \ %__MODULE__{}, attrs) do
    sys_categorie
    |> cast(attrs, [:author, :added, :module, :value, :status])
  end
end
