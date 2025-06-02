defmodule DeeperHub.Schema.SysProfilesConnFriend do
  @moduledoc """
  Schema para representação de sys_profiles_conn_friends no sistema

  Este schema armazena as informações de um sys_profiles_conn_friend.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_profiles_conn_friends" do
    field :initiator, :integer  # int(11)
    field :content, :integer  # int(11)
    field :mutual, :integer  # tinyint(4)
    field :added, :integer  # int(10) unsigned

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_profiles_conn_friend no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    initiator: integer() | nil,
    content: integer() | nil,
    mutual: integer() | nil,
    added: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_profiles_conn_friend.

  ## Parâmetros 
    - `sys_profiles_conn_friend`: Struct do sys_profiles_conn_friend (pode ser %SysProfilesConnFriend{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_profiles_conn_friend \ %__MODULE__{}, attrs) do
    sys_profiles_conn_friend
    |> cast(attrs, [:initiator, :content, :mutual, :added])
    |> validate_required([:initiator, :content, :mutual, :added])
  end

  @doc """
  Changeset para atualização de um sys_profiles_conn_friend existente.

  ## Parâmetros 
    - `sys_profiles_conn_friend`: Struct do sys_profiles_conn_friend (%SysProfilesConnFriend{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_profiles_conn_friend \ %__MODULE__{}, attrs) do
    sys_profiles_conn_friend
    |> cast(attrs, [:initiator, :content, :mutual, :added])
  end
end
