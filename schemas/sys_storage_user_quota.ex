defmodule DeeperHub.Schema.SysStorageUserQuota do
  @moduledoc """
  Schema para representação de sys_storage_user_quotas no sistema

  Este schema armazena as informações de um sys_storage_user_quota.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_storage_user_quotas" do
    field :profile_id, :integer  # int(11)
    field :current_size, :integer  # bigint(20)
    field :current_number, :integer  # int(11)
    field :ts, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_storage_user_quota no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    profile_id: integer() | nil,
    current_size: integer() | nil,
    current_number: integer() | nil,
    ts: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_storage_user_quota.

  ## Parâmetros 
    - `sys_storage_user_quota`: Struct do sys_storage_user_quota (pode ser %SysStorageUserQuota{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_storage_user_quota \ %__MODULE__{}, attrs) do
    sys_storage_user_quota
    |> cast(attrs, [:profile_id, :current_size, :current_number, :ts])
    |> validate_required([:profile_id, :current_size, :current_number, :ts])
  end

  @doc """
  Changeset para atualização de um sys_storage_user_quota existente.

  ## Parâmetros 
    - `sys_storage_user_quota`: Struct do sys_storage_user_quota (%SysStorageUserQuota{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_storage_user_quota \ %__MODULE__{}, attrs) do
    sys_storage_user_quota
    |> cast(attrs, [:profile_id, :current_size, :current_number, :ts])
  end
end
