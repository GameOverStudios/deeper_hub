defmodule DeeperHub.Schema.SysProfile do
  @moduledoc """
  Schema para representação de sys_profiles no sistema

  Este schema armazena as informações de um sys_profile.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_profiles" do
    field :account_id, :integer  # int(10) unsigned
    field :type, :string  # varchar(32)
    field :content_id, :integer  # int(10) unsigned
    field :cfw_value, :integer, default: 2147483647  # int(10) unsigned
    field :cfw_items, :integer, default: 2147483647  # int(10) unsigned
    field :cfu_items, :integer, default: 2147483647  # int(10) unsigned
    field :cfu_locked, :integer, default: 0  # tinyint(4)
    field :status, Ecto.Enum, values: [:active, :pending, :suspended], default: "active"  # enum('active','pending','suspended')

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_profile no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    account_id: integer() | nil,
    type: String.t() | nil,
    content_id: integer() | nil,
    cfw_value: integer() | nil,
    cfw_items: integer() | nil,
    cfu_items: integer() | nil,
    cfu_locked: integer() | nil,
    status: :active | :pending | :suspended | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_profile.

  ## Parâmetros 
    - `sys_profile`: Struct do sys_profile (pode ser %SysProfile{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_profile \ %__MODULE__{}, attrs) do
    sys_profile
    |> cast(attrs, [:account_id, :type, :content_id, :cfw_value, :cfw_items, :cfu_items, :cfu_locked, :status])
    |> validate_required([:account_id, :type, :content_id])
  end

  @doc """
  Changeset para atualização de um sys_profile existente.

  ## Parâmetros 
    - `sys_profile`: Struct do sys_profile (%SysProfile{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_profile \ %__MODULE__{}, attrs) do
    sys_profile
    |> cast(attrs, [:account_id, :type, :content_id, :cfw_value, :cfw_items, :cfu_items, :cfu_locked, :status])
  end
end
