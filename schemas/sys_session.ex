defmodule DeeperHub.Schema.SysSession do
  @moduledoc """
  Schema para representação de sys_sessions no sistema

  Este schema armazena as informações de um sys_session.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_sessions" do
    field :user_id, :integer, default: 0  # int(10) unsigned
    field :data, :string  # text
    field :date, :integer, default: 0  # int(10) unsigned

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_session no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    user_id: integer() | nil,
    data: String.t() | nil,
    date: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_session.

  ## Parâmetros 
    - `sys_session`: Struct do sys_session (pode ser %SysSession{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_session \ %__MODULE__{}, attrs) do
    sys_session
    |> cast(attrs, [:user_id, :data, :date])
  end

  @doc """
  Changeset para atualização de um sys_session existente.

  ## Parâmetros 
    - `sys_session`: Struct do sys_session (%SysSession{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_session \ %__MODULE__{}, attrs) do
    sys_session
    |> cast(attrs, [:user_id, :data, :date])
  end
end
