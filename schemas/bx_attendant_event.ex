defmodule DeeperHub.Schema.BxAttendantEvent do
  @moduledoc """
  Schema para representação de bx_attendant_events no sistema

  Este schema armazena as informações de um bx_attendant_event.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_attendant_events" do
    field :method, :string  # varchar(50)
    field :event, :string  # varchar(50)
    field :added, :integer  # int(11)
    field :processed, :integer  # int(11)
    field :action, :string  # varchar(10)
    field :object_id, :integer  # int(11)
    field :profile_id, :integer  # int(11)
    field :module, :string  # varchar(50)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_attendant_event no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    method: String.t() | nil,
    event: String.t() | nil,
    added: integer() | nil,
    processed: integer() | nil,
    action: String.t() | nil,
    object_id: integer() | nil,
    profile_id: integer() | nil,
    module: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_attendant_event.

  ## Parâmetros 
    - `bx_attendant_event`: Struct do bx_attendant_event (pode ser %BxAttendantEvent{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_attendant_event \ %__MODULE__{}, attrs) do
    bx_attendant_event
    |> cast(attrs, [:method, :event, :added, :processed, :action, :object_id, :profile_id, :module])
    |> validate_required([:method, :event, :action, :module])
  end

  @doc """
  Changeset para atualização de um bx_attendant_event existente.

  ## Parâmetros 
    - `bx_attendant_event`: Struct do bx_attendant_event (%BxAttendantEvent{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_attendant_event \ %__MODULE__{}, attrs) do
    bx_attendant_event
    |> cast(attrs, [:method, :event, :added, :processed, :action, :object_id, :profile_id, :module])
  end
end
