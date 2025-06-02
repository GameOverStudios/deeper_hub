defmodule DeeperHub.Schema.SysStorageMimeType do
  @moduledoc """
  Schema para representação de sys_storage_mime_types no sistema

  Este schema armazena as informações de um sys_storage_mime_type.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_storage_mime_types" do
    field :ext, :string  # varchar(32)
    field :mime_type, :string  # varchar(128)
    field :icon, :string  # varchar(255)
    field :icon_font, :string  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_storage_mime_type no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    ext: String.t() | nil,
    mime_type: String.t() | nil,
    icon: String.t() | nil,
    icon_font: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_storage_mime_type.

  ## Parâmetros 
    - `sys_storage_mime_type`: Struct do sys_storage_mime_type (pode ser %SysStorageMimeType{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_storage_mime_type \ %__MODULE__{}, attrs) do
    sys_storage_mime_type
    |> cast(attrs, [:ext, :mime_type, :icon, :icon_font])
    |> validate_required([:ext, :mime_type, :icon, :icon_font])
  end

  @doc """
  Changeset para atualização de um sys_storage_mime_type existente.

  ## Parâmetros 
    - `sys_storage_mime_type`: Struct do sys_storage_mime_type (%SysStorageMimeType{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_storage_mime_type \ %__MODULE__{}, attrs) do
    sys_storage_mime_type
    |> cast(attrs, [:ext, :mime_type, :icon, :icon_font])
  end
end
