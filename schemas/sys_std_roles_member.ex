defmodule DeeperHub.Schema.SysStdRolesMember do
  @moduledoc """
  Schema para representação de sys_std_roles_members no sistema

  Este schema armazena as informações de um sys_std_roles_member.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_std_roles_members" do
    field :account_id, :integer, default: 0  # int(11) unsigned
    field :role, :integer, default: 0  # int(11) unsigned

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_std_roles_member no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    account_id: integer() | nil,
    role: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_std_roles_member.

  ## Parâmetros 
    - `sys_std_roles_member`: Struct do sys_std_roles_member (pode ser %SysStdRolesMember{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_std_roles_member \ %__MODULE__{}, attrs) do
    sys_std_roles_member
    |> cast(attrs, [:account_id, :role])
    |> unique_constraint(:account_id)
  end

  @doc """
  Changeset para atualização de um sys_std_roles_member existente.

  ## Parâmetros 
    - `sys_std_roles_member`: Struct do sys_std_roles_member (%SysStdRolesMember{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_std_roles_member \ %__MODULE__{}, attrs) do
    sys_std_roles_member
    |> cast(attrs, [:account_id, :role])
    |> unique_constraint(:account_id)
  end
end
