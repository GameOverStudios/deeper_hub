defmodule DeeperHub.Schema.BxEventsInterval do
  @moduledoc """
  Schema para representação de bx_events_intervals no sistema

  Este schema armazena as informações de um bx_events_interval.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_events_intervals" do
    field :interval_id, :integer  # int(10) unsigned
    field :event_id, :integer  # int(10) unsigned
    field :repeat_year, :integer  # int(11)
    field :repeat_month, :integer  # int(11)
    field :repeat_week_of_month, :integer  # int(11)
    field :repeat_day_of_month, :integer  # int(11)
    field :repeat_day_of_week, :integer  # int(11)
    field :repeat_stop, :integer  # int(10) unsigned

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_events_interval no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    interval_id: integer() | nil,
    event_id: integer() | nil,
    repeat_year: integer() | nil,
    repeat_month: integer() | nil,
    repeat_week_of_month: integer() | nil,
    repeat_day_of_month: integer() | nil,
    repeat_day_of_week: integer() | nil,
    repeat_stop: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_events_interval.

  ## Parâmetros 
    - `bx_events_interval`: Struct do bx_events_interval (pode ser %BxEventsInterval{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_events_interval \ %__MODULE__{}, attrs) do
    bx_events_interval
    |> cast(attrs, [:interval_id, :event_id, :repeat_year, :repeat_month, :repeat_week_of_month, :repeat_day_of_month, :repeat_day_of_week, :repeat_stop])
    |> validate_required([:interval_id, :event_id, :repeat_year, :repeat_month, :repeat_week_of_month, :repeat_day_of_month, :repeat_day_of_week, :repeat_stop])
  end

  @doc """
  Changeset para atualização de um bx_events_interval existente.

  ## Parâmetros 
    - `bx_events_interval`: Struct do bx_events_interval (%BxEventsInterval{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_events_interval \ %__MODULE__{}, attrs) do
    bx_events_interval
    |> cast(attrs, [:interval_id, :event_id, :repeat_year, :repeat_month, :repeat_week_of_month, :repeat_day_of_month, :repeat_day_of_week, :repeat_stop])
  end
end
