defmodule DeeperHub.Schema.SysQueuePush do
  @moduledoc """
  Schema para representação de sys_queue_pushs no sistema

  Este schema armazena as informações de um sys_queue_push.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_queue_push" do
    field :profile_id, :integer, default: 0  # int(11)
    field :message, :string, default: "''"  # text

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_queue_push no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    profile_id: integer() | nil,
    message: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_queue_push.

  ## Parâmetros 
    - `sys_queue_push`: Struct do sys_queue_push (pode ser %SysQueuePush{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_queue_push \ %__MODULE__{}, attrs) do
    sys_queue_push
    |> cast(attrs, [:profile_id, :message])
  end

  @doc """
  Changeset para atualização de um sys_queue_push existente.

  ## Parâmetros 
    - `sys_queue_push`: Struct do sys_queue_push (%SysQueuePush{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_queue_push \ %__MODULE__{}, attrs) do
    sys_queue_push
    |> cast(attrs, [:profile_id, :message])
  end
end
