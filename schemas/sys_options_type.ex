defmodule DeeperHub.Schema.SysOptionsType do
  @moduledoc """
  Schema para representação de sys_options_types no sistema

  Este schema armazena as informações de um sys_options_type.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_options_types" do
    field :group, :string, default: ""  # varchar(64)
    field :name, :string, default: ""  # varchar(64)
    field :caption, :string, default: ""  # varchar(64)
    field :icon, :string, default: ""  # varchar(255)
    field :order, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_options_type no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    group: String.t() | nil,
    name: String.t() | nil,
    caption: String.t() | nil,
    icon: String.t() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_options_type.

  ## Parâmetros 
    - `sys_options_type`: Struct do sys_options_type (pode ser %SysOptionsType{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_options_type \ %__MODULE__{}, attrs) do
    sys_options_type
    |> cast(attrs, [:group, :name, :caption, :icon, :order])
    |> validate_required([:group, :name, :caption, :icon])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset para atualização de um sys_options_type existente.

  ## Parâmetros 
    - `sys_options_type`: Struct do sys_options_type (%SysOptionsType{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_options_type \ %__MODULE__{}, attrs) do
    sys_options_type
    |> cast(attrs, [:group, :name, :caption, :icon, :order])
    |> unique_constraint(:name)
  end
end
