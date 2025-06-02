defmodule DeeperHub.Schema.SysAccountsPicturesResized do
  @moduledoc """
  Schema para representação de sys_accounts_pictures_resizeds no sistema

  Este schema armazena as informações de um sys_accounts_pictures_resized.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_accounts_pictures_resized" do
    field :profile_id, :integer  # int(10) unsigned
    field :remote_id, :string  # varchar(128)
    field :path, :string  # varchar(255)
    field :file_name, :string  # varchar(255)
    field :mime_type, :string  # varchar(128)
    field :ext, :string  # varchar(32)
    field :size, :integer  # bigint(20)
    field :added, :integer  # int(11)
    field :modified, :integer  # int(11)
    field :private, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_accounts_pictures_resized no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    profile_id: integer() | nil,
    remote_id: String.t() | nil,
    path: String.t() | nil,
    file_name: String.t() | nil,
    mime_type: String.t() | nil,
    ext: String.t() | nil,
    size: integer() | nil,
    added: integer() | nil,
    modified: integer() | nil,
    private: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_accounts_pictures_resized.

  ## Parâmetros 
    - `sys_accounts_pictures_resized`: Struct do sys_accounts_pictures_resized (pode ser %SysAccountsPicturesResized{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_accounts_pictures_resized \ %__MODULE__{}, attrs) do
    sys_accounts_pictures_resized
    |> cast(attrs, [:profile_id, :remote_id, :path, :file_name, :mime_type, :ext, :size, :added, :modified, :private])
    |> validate_required([:profile_id, :remote_id, :path, :file_name, :mime_type, :ext, :size, :added, :modified, :private])
    |> unique_constraint(:remote_id)
  end

  @doc """
  Changeset para atualização de um sys_accounts_pictures_resized existente.

  ## Parâmetros 
    - `sys_accounts_pictures_resized`: Struct do sys_accounts_pictures_resized (%SysAccountsPicturesResized{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_accounts_pictures_resized \ %__MODULE__{}, attrs) do
    sys_accounts_pictures_resized
    |> cast(attrs, [:profile_id, :remote_id, :path, :file_name, :mime_type, :ext, :size, :added, :modified, :private])
    |> unique_constraint(:remote_id)
  end
end
