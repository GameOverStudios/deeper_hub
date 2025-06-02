defmodule DeeperHub.Schema.BxEventsCheckIn do
  @moduledoc """
  Schema para representação de bx_events_check_ins no sistema

  Este schema armazena as informações de um bx_events_check_in.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_events_check_in" do
    field :profile_id, :integer  # int(10) unsigned
    field :event_id, :integer  # int(10) unsigned

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_events_check_in no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    profile_id: integer() | nil,
    event_id: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_events_check_in.

  ## Parâmetros 
    - `bx_events_check_in`: Struct do bx_events_check_in (pode ser %BxEventsCheckIn{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_events_check_in \ %__MODULE__{}, attrs) do
    bx_events_check_in
    |> cast(attrs, [:profile_id, :event_id])
    |> validate_required([:profile_id, :event_id])
    |> unique_constraint(:profile_id)
  end

  @doc """
  Changeset para atualização de um bx_events_check_in existente.

  ## Parâmetros 
    - `bx_events_check_in`: Struct do bx_events_check_in (%BxEventsCheckIn{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_events_check_in \ %__MODULE__{}, attrs) do
    bx_events_check_in
    |> cast(attrs, [:profile_id, :event_id])
    |> unique_constraint(:profile_id)
  end
end
