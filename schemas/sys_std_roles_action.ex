defmodule DeeperHub.Schema.SysStdRolesAction do
  @moduledoc """
  Schema para representação de sys_std_roles_actions no sistema

  Este schema armazena as informações de um sys_std_roles_action.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_std_roles_actions" do
    field :name, :string, default: ""  # varchar(64)
    field :title, :string  # varchar(255)
    field :description, :string  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_std_roles_action no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t() | nil,
    title: String.t() | nil,
    description: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_std_roles_action.

  ## Parâmetros 
    - `sys_std_roles_action`: Struct do sys_std_roles_action (pode ser %SysStdRolesAction{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_std_roles_action \ %__MODULE__{}, attrs) do
    sys_std_roles_action
    |> cast(attrs, [:name, :title, :description])
    |> validate_required([:name, :title, :description])
  end

  @doc """
  Changeset para atualização de um sys_std_roles_action existente.

  ## Parâmetros 
    - `sys_std_roles_action`: Struct do sys_std_roles_action (%SysStdRolesAction{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_std_roles_action \ %__MODULE__{}, attrs) do
    sys_std_roles_action
    |> cast(attrs, [:name, :title, :description])
  end
end
