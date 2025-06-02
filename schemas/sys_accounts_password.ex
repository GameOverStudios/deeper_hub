defmodule DeeperHub.Schema.SysAccountsPassword do
  @moduledoc """
  Schema para representação de sys_accounts_passwords no sistema

  Este schema armazena as informações de um sys_accounts_password.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_accounts_password" do
    field :account_id, :integer  # int(10)
    field :password, :string  # varchar(40)
    field :password_changed, :integer, default: 0  # int(11)
    field :salt, :string  # varchar(10)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_accounts_password no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    account_id: integer() | nil,
    password: String.t() | nil,
    password_changed: integer() | nil,
    salt: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_accounts_password.

  ## Parâmetros 
    - `sys_accounts_password`: Struct do sys_accounts_password (pode ser %SysAccountsPassword{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_accounts_password \ %__MODULE__{}, attrs) do
    sys_accounts_password
    |> cast(attrs, [:account_id, :password, :password_changed, :salt])
    |> validate_required([:account_id, :password, :salt])
    |> validate_password()
    |> put_password_hash()
  end

  @doc """
  Changeset para atualização de um sys_accounts_password existente.

  ## Parâmetros 
    - `sys_accounts_password`: Struct do sys_accounts_password (%SysAccountsPassword{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_accounts_password \ %__MODULE__{}, attrs) do
    sys_accounts_password
    |> cast(attrs, [:account_id, :password_changed, :salt])
  end
end
