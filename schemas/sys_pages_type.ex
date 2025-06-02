defmodule DeeperHub.Schema.SysPagesType do
  @moduledoc """
  Schema para representação de sys_pages_types no sistema

  Este schema armazena as informações de um sys_pages_type.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_pages_types" do
    field :title, :string  # varchar(255)
    field :template, :string  # varchar(255)
    field :order, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_pages_type no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    title: String.t() | nil,
    template: String.t() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_pages_type.

  ## Parâmetros 
    - `sys_pages_type`: Struct do sys_pages_type (pode ser %SysPagesType{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_pages_type \ %__MODULE__{}, attrs) do
    sys_pages_type
    |> cast(attrs, [:title, :template, :order])
    |> validate_required([:title, :template, :order])
  end

  @doc """
  Changeset para atualização de um sys_pages_type existente.

  ## Parâmetros 
    - `sys_pages_type`: Struct do sys_pages_type (%SysPagesType{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_pages_type \ %__MODULE__{}, attrs) do
    sys_pages_type
    |> cast(attrs, [:title, :template, :order])
  end
end
