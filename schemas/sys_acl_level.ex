defmodule DeeperHub.Schema.SysAclLevel do
  @moduledoc """
  Schema para representação de sys_acl_levels no sistema

  Este schema armazena as informações de um sys_acl_level.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_acl_levels" do
    field :ID, :integer  # int(10) unsigned
    field :Name, :string, default: ""  # varchar(100)
    field :Icon, :string, default: "''"  # text
    field :Description, :string, default: ""  # varchar(255)
    field :Active, Ecto.Enum, values: [:yes, :no], default: "no"  # enum('yes','no')
    field :Purchasable, Ecto.Enum, values: [:yes, :no], default: "yes"  # enum('yes','no')
    field :Removable, Ecto.Enum, values: [:yes, :no], default: "yes"  # enum('yes','no')
    field :QuotaSize, :integer  # bigint(20)
    field :QuotaNumber, :integer  # int(11)
    field :QuotaMaxFileSize, :integer  # bigint(20)
    field :Order, :integer, default: 0  # int(11)
    field :PasswordExpired, :integer, default: 0  # int(11)
    field :PasswordExpiredNotify, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_acl_level no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    ID: integer() | nil,
    Name: String.t() | nil,
    Icon: String.t() | nil,
    Description: String.t() | nil,
    Active: :yes | :no | nil,
    Purchasable: :yes | :no | nil,
    Removable: :yes | :no | nil,
    QuotaSize: integer() | nil,
    QuotaNumber: integer() | nil,
    QuotaMaxFileSize: integer() | nil,
    Order: integer() | nil,
    PasswordExpired: integer() | nil,
    PasswordExpiredNotify: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_acl_level.

  ## Parâmetros 
    - `sys_acl_level`: Struct do sys_acl_level (pode ser %SysAclLevel{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_acl_level \ %__MODULE__{}, attrs) do
    sys_acl_level
    |> cast(attrs, [:ID, :Name, :Icon, :Description, :Active, :Purchasable, :Removable, :QuotaSize, :QuotaNumber, :QuotaMaxFileSize, :Order, :PasswordExpired, :PasswordExpiredNotify])
    |> validate_required([:ID, :Name, :Description, :QuotaSize, :QuotaNumber, :QuotaMaxFileSize])
    |> unique_constraint(:Name)
  end

  @doc """
  Changeset para atualização de um sys_acl_level existente.

  ## Parâmetros 
    - `sys_acl_level`: Struct do sys_acl_level (%SysAclLevel{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_acl_level \ %__MODULE__{}, attrs) do
    sys_acl_level
    |> cast(attrs, [:ID, :Name, :Icon, :Description, :Active, :Purchasable, :Removable, :QuotaSize, :QuotaNumber, :QuotaMaxFileSize, :Order, :PasswordExpired, :PasswordExpiredNotify])
    |> unique_constraint(:Name)
  end
end
