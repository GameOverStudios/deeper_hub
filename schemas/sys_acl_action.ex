defmodule DeeperHub.Schema.SysAclAction do
  @moduledoc """
  Schema para representação de sys_acl_actions no sistema

  Este schema armazena as informações de um sys_acl_action.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_acl_actions" do
    field :ID, :integer  # int(10) unsigned
    field :Module, :string  # varchar(32)
    field :Name, :string, default: ""  # varchar(255)
    field :AdditionalParamName, :string  # varchar(80)
    field :Title, :string  # varchar(255)
    field :Desc, :string  # varchar(255)
    field :Countable, :integer, default: 0  # tinyint(4)
    field :DisabledForLevels, :integer, default: 3  # int(10) unsigned

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_acl_action no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    ID: integer() | nil,
    Module: String.t() | nil,
    Name: String.t() | nil,
    AdditionalParamName: String.t() | nil,
    Title: String.t() | nil,
    Desc: String.t() | nil,
    Countable: integer() | nil,
    DisabledForLevels: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_acl_action.

  ## Parâmetros 
    - `sys_acl_action`: Struct do sys_acl_action (pode ser %SysAclAction{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_acl_action \ %__MODULE__{}, attrs) do
    sys_acl_action
    |> cast(attrs, [:ID, :Module, :Name, :AdditionalParamName, :Title, :Desc, :Countable, :DisabledForLevels])
    |> validate_required([:ID, :Module, :Name, :Title, :Desc])
  end

  @doc """
  Changeset para atualização de um sys_acl_action existente.

  ## Parâmetros 
    - `sys_acl_action`: Struct do sys_acl_action (%SysAclAction{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_acl_action \ %__MODULE__{}, attrs) do
    sys_acl_action
    |> cast(attrs, [:ID, :Module, :Name, :AdditionalParamName, :Title, :Desc, :Countable, :DisabledForLevels])
  end
end
