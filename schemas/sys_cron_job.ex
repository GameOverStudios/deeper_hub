defmodule DeeperHub.Schema.SysCronJob do
  @moduledoc """
  Schema para representação de sys_cron_jobs no sistema

  Este schema armazena as informações de um sys_cron_job.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_cron_jobs" do
    field :name, :string, default: ""  # varchar(128)
    field :time, :string, default: "*"  # varchar(128)
    field :class, :string, default: ""  # varchar(128)
    field :file, :string, default: ""  # varchar(255)
    field :service_call, :string, default: "''"  # text
    field :ts, :integer  # int(11)
    field :timing, :float  # float

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_cron_job no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t() | nil,
    time: String.t() | nil,
    class: String.t() | nil,
    file: String.t() | nil,
    service_call: String.t() | nil,
    ts: integer() | nil,
    timing: float() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_cron_job.

  ## Parâmetros 
    - `sys_cron_job`: Struct do sys_cron_job (pode ser %SysCronJob{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_cron_job \ %__MODULE__{}, attrs) do
    sys_cron_job
    |> cast(attrs, [:name, :time, :class, :file, :service_call, :ts, :timing])
    |> validate_required([:name, :class, :file, :ts, :timing])
  end

  @doc """
  Changeset para atualização de um sys_cron_job existente.

  ## Parâmetros 
    - `sys_cron_job`: Struct do sys_cron_job (%SysCronJob{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_cron_job \ %__MODULE__{}, attrs) do
    sys_cron_job
    |> cast(attrs, [:name, :time, :class, :file, :service_call, :ts, :timing])
  end
end
