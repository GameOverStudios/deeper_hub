defmodule DeeperHub.Schema.SysTranscoderQueue do
  @moduledoc """
  Schema para representação de sys_transcoder_queues no sistema

  Este schema armazena as informações de um sys_transcoder_queue.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_transcoder_queue" do
    field :transcoder_object, :string  # varchar(64)
    field :profile_id, :integer  # int(10) unsigned
    field :file_url_source, :string  # varchar(255)
    field :file_id_source, :string  # varchar(255)
    field :file_url_result, :string  # varchar(255)
    field :file_ext_result, :string  # varchar(255)
    field :file_id_result, :integer  # int(11)
    field :server, :string  # varchar(255)
    field :status, Ecto.Enum, values: [:pending, :processing, :complete, :failed, :delete]  # enum('pending','processing','complete','failed','delete')
    field :pid, :integer, default: 0  # int(10) unsigned
    field :added, :integer  # int(11)
    field :changed, :integer  # int(11)
    field :log, :string  # text

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_transcoder_queue no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    transcoder_object: String.t() | nil,
    profile_id: integer() | nil,
    file_url_source: String.t() | nil,
    file_id_source: String.t() | nil,
    file_url_result: String.t() | nil,
    file_ext_result: String.t() | nil,
    file_id_result: integer() | nil,
    server: String.t() | nil,
    status: :pending | :processing | :complete | :failed | :delete | nil,
    pid: integer() | nil,
    added: integer() | nil,
    changed: integer() | nil,
    log: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_transcoder_queue.

  ## Parâmetros 
    - `sys_transcoder_queue`: Struct do sys_transcoder_queue (pode ser %SysTranscoderQueue{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_transcoder_queue \ %__MODULE__{}, attrs) do
    sys_transcoder_queue
    |> cast(attrs, [:transcoder_object, :profile_id, :file_url_source, :file_id_source, :file_url_result, :file_ext_result, :file_id_result, :server, :status, :pid, :added, :changed, :log])
    |> validate_required([:transcoder_object, :profile_id, :file_url_source, :file_id_source, :file_url_result, :file_ext_result, :file_id_result, :server, :status, :added, :changed, :log])
  end

  @doc """
  Changeset para atualização de um sys_transcoder_queue existente.

  ## Parâmetros 
    - `sys_transcoder_queue`: Struct do sys_transcoder_queue (%SysTranscoderQueue{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_transcoder_queue \ %__MODULE__{}, attrs) do
    sys_transcoder_queue
    |> cast(attrs, [:transcoder_object, :profile_id, :file_url_source, :file_id_source, :file_url_result, :file_ext_result, :file_id_result, :server, :status, :pid, :added, :changed, :log])
  end
end
