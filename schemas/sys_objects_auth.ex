defmodule DeeperHub.Schema.SysObjectsAuth do
  @moduledoc """
  Schema para representação de sys_objects_auths no sistema

  Este schema armazena as informações de um sys_objects_auth.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_objects_auths" do
    field :ID, :integer  # int(10) unsigned
    field :Name, :string  # varchar(64)
    field :Title, :string  # varchar(128)
    field :Link, :string  # varchar(255)
    field :OnClick, :string  # varchar(255)
    field :Icon, :string  # varchar(64)
    field :Style, :string  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_objects_auth no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    ID: integer() | nil,
    Name: String.t() | nil,
    Title: String.t() | nil,
    Link: String.t() | nil,
    OnClick: String.t() | nil,
    Icon: String.t() | nil,
    Style: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_objects_auth.

  ## Parâmetros 
    - `sys_objects_auth`: Struct do sys_objects_auth (pode ser %SysObjectsAuth{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_objects_auth \ %__MODULE__{}, attrs) do
    sys_objects_auth
    |> cast(attrs, [:ID, :Name, :Title, :Link, :OnClick, :Icon, :Style])
    |> validate_required([:ID, :Name, :Title, :Link, :OnClick, :Icon, :Style])
  end

  @doc """
  Changeset para atualização de um sys_objects_auth existente.

  ## Parâmetros 
    - `sys_objects_auth`: Struct do sys_objects_auth (%SysObjectsAuth{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_objects_auth \ %__MODULE__{}, attrs) do
    sys_objects_auth
    |> cast(attrs, [:ID, :Name, :Title, :Link, :OnClick, :Icon, :Style])
  end
end
