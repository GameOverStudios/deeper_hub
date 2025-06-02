defmodule DeeperHub.Schema.SysTranscoderImagesFile do
  @moduledoc """
  Schema para representação de sys_transcoder_images_files no sistema

  Este schema armazena as informações de um sys_transcoder_images_file.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_transcoder_images_files" do
    field :transcoder_object, :string  # varchar(64)
    field :file_id, :integer  # int(11)
    field :handler, :string  # varchar(255)
    field :atime, :integer  # int(11)
    field :data, :string  # text

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_transcoder_images_file no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    transcoder_object: String.t() | nil,
    file_id: integer() | nil,
    handler: String.t() | nil,
    atime: integer() | nil,
    data: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_transcoder_images_file.

  ## Parâmetros 
    - `sys_transcoder_images_file`: Struct do sys_transcoder_images_file (pode ser %SysTranscoderImagesFile{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_transcoder_images_file \ %__MODULE__{}, attrs) do
    sys_transcoder_images_file
    |> cast(attrs, [:transcoder_object, :file_id, :handler, :atime, :data])
    |> validate_required([:transcoder_object, :file_id, :handler, :atime, :data])
  end

  @doc """
  Changeset para atualização de um sys_transcoder_images_file existente.

  ## Parâmetros 
    - `sys_transcoder_images_file`: Struct do sys_transcoder_images_file (%SysTranscoderImagesFile{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_transcoder_images_file \ %__MODULE__{}, attrs) do
    sys_transcoder_images_file
    |> cast(attrs, [:transcoder_object, :file_id, :handler, :atime, :data])
  end
end
