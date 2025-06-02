defmodule DeeperHub.Schema.SysGridAction do
  @moduledoc """
  Schema para representação de sys_grid_actions no sistema

  Este schema armazena as informações de um sys_grid_action.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_grid_actions" do
    field :object, :string  # varchar(64)
    field :type, Ecto.Enum, values: [:bulk, :single, :independent]  # enum('bulk','single','independent')
    field :name, :string  # varchar(255)
    field :title, :string  # varchar(255)
    field :icon, :string  # text
    field :icon_only, :integer, default: 0  # tinyint(4)
    field :confirm, :integer, default: 1  # tinyint(4)
    field :active, :integer, default: 1  # tinyint(4)
    field :order, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_grid_action no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object: String.t() | nil,
    type: :bulk | :single | :independent | nil,
    name: String.t() | nil,
    title: String.t() | nil,
    icon: String.t() | nil,
    icon_only: integer() | nil,
    confirm: integer() | nil,
    active: integer() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_grid_action.

  ## Parâmetros 
    - `sys_grid_action`: Struct do sys_grid_action (pode ser %SysGridAction{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_grid_action \ %__MODULE__{}, attrs) do
    sys_grid_action
    |> cast(attrs, [:object, :type, :name, :title, :icon, :icon_only, :confirm, :active, :order])
    |> validate_required([:object, :type, :name, :title, :icon, :order])
  end

  @doc """
  Changeset para atualização de um sys_grid_action existente.

  ## Parâmetros 
    - `sys_grid_action`: Struct do sys_grid_action (%SysGridAction{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_grid_action \ %__MODULE__{}, attrs) do
    sys_grid_action
    |> cast(attrs, [:object, :type, :name, :title, :icon, :icon_only, :confirm, :active, :order])
  end
end
