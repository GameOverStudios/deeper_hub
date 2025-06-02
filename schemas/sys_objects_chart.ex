defmodule DeeperHub.Schema.SysObjectsChart do
  @moduledoc """
  Schema para representação de sys_objects_charts no sistema

  Este schema armazena as informações de um sys_objects_chart.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_objects_chart" do
    field :object, :string  # varchar(32)
    field :title, :string  # varchar(255)
    field :table, :string  # varchar(255)
    field :field_date_ts, :string  # varchar(255)
    field :field_date_dt, :string  # varchar(255)
    field :field_status, :string  # varchar(255)
    field :column_date, :integer, default: 0  # int(11)
    field :column_count, :integer, default: 1  # int(11)
    field :type, :string  # varchar(255)
    field :options, :string  # text
    field :query, :string  # text
    field :active, :integer, default: 1  # tinyint(4)
    field :order, :integer  # int(11)
    field :class_name, :string, default: ""  # varchar(32)
    field :class_file, :string, default: ""  # varchar(256)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_objects_chart no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object: String.t() | nil,
    title: String.t() | nil,
    table: String.t() | nil,
    field_date_ts: String.t() | nil,
    field_date_dt: String.t() | nil,
    field_status: String.t() | nil,
    column_date: integer() | nil,
    column_count: integer() | nil,
    type: String.t() | nil,
    options: String.t() | nil,
    query: String.t() | nil,
    active: integer() | nil,
    order: integer() | nil,
    class_name: String.t() | nil,
    class_file: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_objects_chart.

  ## Parâmetros 
    - `sys_objects_chart`: Struct do sys_objects_chart (pode ser %SysObjectsChart{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_objects_chart \ %__MODULE__{}, attrs) do
    sys_objects_chart
    |> cast(attrs, [:object, :title, :table, :field_date_ts, :field_date_dt, :field_status, :column_date, :column_count, :type, :options, :query, :active, :order, :class_name, :class_file])
    |> validate_required([:object, :title, :table, :field_date_ts, :field_date_dt, :field_status, :type, :options, :query, :order, :class_name, :class_file])
    |> unique_constraint(:object)
  end

  @doc """
  Changeset para atualização de um sys_objects_chart existente.

  ## Parâmetros 
    - `sys_objects_chart`: Struct do sys_objects_chart (%SysObjectsChart{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_objects_chart \ %__MODULE__{}, attrs) do
    sys_objects_chart
    |> cast(attrs, [:object, :title, :table, :field_date_ts, :field_date_dt, :field_status, :column_date, :column_count, :type, :options, :query, :active, :order, :class_name, :class_file])
    |> unique_constraint(:object)
  end
end
