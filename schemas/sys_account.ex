defmodule DeeperHub.Schema.SysAccount do
  @moduledoc """
  Schema para representação de sys_accounts no sistema

  Este schema armazena as informações de um sys_account.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_accounts" do
    field :profile_id, :integer  # int(10) unsigned
    field :name, :string  # varchar(255)
    field :picture, :integer, default: 0  # int(11)
    field :email, :string  # varchar(255)
    field :email_confirmed, :integer, default: 0  # tinyint(4)
    field :phone, :string  # varchar(255)
    field :phone_confirmed, :integer, default: 0  # tinyint(4)
    field :receive_updates, :integer, default: 1  # tinyint(4)
    field :receive_news, :integer, default: 1  # tinyint(4)
    field :password, :string  # varchar(40)
    field :password_changed, :integer, default: 0  # int(11)
    field :salt, :string  # varchar(10)
    field :role, :integer, default: 1  # tinyint(4)
    field :lang_id, :integer, default: 0  # int(10) unsigned
    field :added, :integer, default: 0  # int(11)
    field :changed, :integer, default: 0  # int(11)
    field :logged, :integer, default: 0  # int(11)
    field :ip, :string, default: ""  # varchar(40)
    field :referred, :string, default: ""  # varchar(255)
    field :login_attempts, :integer, default: 0  # tinyint(4)
    field :locked, :integer, default: 0  # tinyint(4)
    field :active, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_account no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    profile_id: integer() | nil,
    name: String.t() | nil,
    picture: integer() | nil,
    email: String.t() | nil,
    email_confirmed: integer() | nil,
    phone: String.t() | nil,
    phone_confirmed: integer() | nil,
    receive_updates: integer() | nil,
    receive_news: integer() | nil,
    password: String.t() | nil,
    password_changed: integer() | nil,
    salt: String.t() | nil,
    role: integer() | nil,
    lang_id: integer() | nil,
    added: integer() | nil,
    changed: integer() | nil,
    logged: integer() | nil,
    ip: String.t() | nil,
    referred: String.t() | nil,
    login_attempts: integer() | nil,
    locked: integer() | nil,
    active: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_account.

  ## Parâmetros 
    - `sys_account`: Struct do sys_account (pode ser %SysAccount{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_account \ %__MODULE__{}, attrs) do
    sys_account
    |> cast(attrs, [:profile_id, :name, :picture, :email, :email_confirmed, :phone, :phone_confirmed, :receive_updates, :receive_news, :password, :password_changed, :salt, :role, :lang_id, :added, :changed, :logged, :ip, :referred, :login_attempts, :locked, :active])
    |> validate_required([:profile_id, :name, :email, :phone, :password, :salt, :ip, :referred])
    |> validate_email()
    |> validate_password()
    |> put_password_hash()
    |> unique_constraint(:email)
  end

  @doc """
  Changeset para atualização de um sys_account existente.

  ## Parâmetros 
    - `sys_account`: Struct do sys_account (%SysAccount{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_account \ %__MODULE__{}, attrs) do
    sys_account
    |> cast(attrs, [:profile_id, :name, :picture, :email, :email_confirmed, :phone, :phone_confirmed, :receive_updates, :receive_news, :password_changed, :salt, :role, :lang_id, :added, :changed, :logged, :ip, :referred, :login_attempts, :locked, :active])
    |> validate_email()
    |> unique_constraint(:email)
  end
end
