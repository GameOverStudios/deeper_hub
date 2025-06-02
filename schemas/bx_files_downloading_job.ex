defmodule DeeperHub.Schema.BxFilesDownloadingJob do
  @moduledoc """
  Schema para representação de bx_files_downloading_jobs no sistema

  Este schema armazena as informações de um bx_files_downloading_job.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_files_downloading_jobs" do
    field :name, :string  # varchar(255)
    field :owner, :integer  # int(11)
    field :files, :string  # mediumtext
    field :result, :string  # text
    field :started, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_files_downloading_job no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t() | nil,
    owner: integer() | nil,
    files: String.t() | nil,
    result: String.t() | nil,
    started: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_files_downloading_job.

  ## Parâmetros 
    - `bx_files_downloading_job`: Struct do bx_files_downloading_job (pode ser %BxFilesDownloadingJob{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_files_downloading_job \ %__MODULE__{}, attrs) do
    bx_files_downloading_job
    |> cast(attrs, [:name, :owner, :files, :result, :started])
    |> validate_required([:name, :owner, :files, :result, :started])
  end

  @doc """
  Changeset para atualização de um bx_files_downloading_job existente.

  ## Parâmetros 
    - `bx_files_downloading_job`: Struct do bx_files_downloading_job (%BxFilesDownloadingJob{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_files_downloading_job \ %__MODULE__{}, attrs) do
    bx_files_downloading_job
    |> cast(attrs, [:name, :owner, :files, :result, :started])
  end
end
