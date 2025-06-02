defmodule DeeperHub.Schema.SysObjectsUploader do
  @moduledoc """
  Schema para representação de sys_objects_uploaders no sistema

  Este schema armazena as informações de um sys_objects_uploader.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_objects_uploader" do
    field :object, :string  # varchar(64)
    field :active, :integer  # tinyint(4)
    field :override_class_name, :string  # varchar(255)
    field :override_class_file, :string  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_objects_uploader no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object: String.t() | nil,
    active: integer() | nil,
    override_class_name: String.t() | nil,
    override_class_file: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_objects_uploader.

  ## Parâmetros 
    - `sys_objects_uploader`: Struct do sys_objects_uploader (pode ser %SysObjectsUploader{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_objects_uploader \ %__MODULE__{}, attrs) do
    sys_objects_uploader
    |> cast(attrs, [:object, :active, :override_class_name, :override_class_file])
    |> validate_required([:object, :active, :override_class_name, :override_class_file])
    |> unique_constraint(:object)
  end

  @doc """
  Changeset para atualização de um sys_objects_uploader existente.

  ## Parâmetros 
    - `sys_objects_uploader`: Struct do sys_objects_uploader (%SysObjectsUploader{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_objects_uploader \ %__MODULE__{}, attrs) do
    sys_objects_uploader
    |> cast(attrs, [:object, :active, :override_class_name, :override_class_file])
    |> unique_constraint(:object)
  end
end
