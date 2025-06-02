defmodule DeeperHub.Schema.SysBackgroundJob do
  @moduledoc """
  Schema para representação de sys_background_jobs no sistema

  Este schema armazena as informações de um sys_background_job.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_background_jobs" do
    field :name, :string, default: ""  # varchar(128)
    field :added, :integer, default: 0  # int(11) unsigned
    field :priority, :integer, default: 0  # tinyint(4) unsigned
    field :service_call, :string, default: "''"  # text
    field :status, :string, default: "awaiting"  # varchar(16)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_background_job no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t() | nil,
    added: integer() | nil,
    priority: integer() | nil,
    service_call: String.t() | nil,
    status: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_background_job.

  ## Parâmetros 
    - `sys_background_job`: Struct do sys_background_job (pode ser %SysBackgroundJob{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_background_job \ %__MODULE__{}, attrs) do
    sys_background_job
    |> cast(attrs, [:name, :added, :priority, :service_call, :status])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset para atualização de um sys_background_job existente.

  ## Parâmetros 
    - `sys_background_job`: Struct do sys_background_job (%SysBackgroundJob{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_background_job \ %__MODULE__{}, attrs) do
    sys_background_job
    |> cast(attrs, [:name, :added, :priority, :service_call, :status])
    |> unique_constraint(:name)
  end
end
