defmodule DeeperHub.Schema.SysStdRolesActions2role do
  @moduledoc """
  Schema para representação de sys_std_roles_actions2roles no sistema

  Este schema armazena as informações de um sys_std_roles_actions2role.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_std_roles_actions2roles" do
    field :role_id, :integer, default: 0  # int(11) unsigned
    field :action_id, :integer, default: 0  # int(11) unsigned

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_std_roles_actions2role no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    role_id: integer() | nil,
    action_id: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_std_roles_actions2role.

  ## Parâmetros 
    - `sys_std_roles_actions2role`: Struct do sys_std_roles_actions2role (pode ser %SysStdRolesActions2role{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_std_roles_actions2role \ %__MODULE__{}, attrs) do
    sys_std_roles_actions2role
    |> cast(attrs, [:role_id, :action_id])
  end

  @doc """
  Changeset para atualização de um sys_std_roles_actions2role existente.

  ## Parâmetros 
    - `sys_std_roles_actions2role`: Struct do sys_std_roles_actions2role (%SysStdRolesActions2role{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_std_roles_actions2role \ %__MODULE__{}, attrs) do
    sys_std_roles_actions2role
    |> cast(attrs, [:role_id, :action_id])
  end
end
