defmodule DeeperHub.Schema.SysObjectsPush do
  @moduledoc """
  Schema para representação de sys_objects_pushs no sistema

  Este schema armazena as informações de um sys_objects_push.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_objects_push" do
    field :object, :string  # varchar(64)
    field :title, :string  # varchar(255)
    field :override_class_name, :string  # varchar(255)
    field :override_class_file, :string  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_objects_push no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object: String.t() | nil,
    title: String.t() | nil,
    override_class_name: String.t() | nil,
    override_class_file: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_objects_push.

  ## Parâmetros 
    - `sys_objects_push`: Struct do sys_objects_push (pode ser %SysObjectsPush{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_objects_push \ %__MODULE__{}, attrs) do
    sys_objects_push
    |> cast(attrs, [:object, :title, :override_class_name, :override_class_file])
    |> validate_required([:object, :title, :override_class_name, :override_class_file])
    |> unique_constraint(:object)
  end

  @doc """
  Changeset para atualização de um sys_objects_push existente.

  ## Parâmetros 
    - `sys_objects_push`: Struct do sys_objects_push (%SysObjectsPush{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_objects_push \ %__MODULE__{}, attrs) do
    sys_objects_push
    |> cast(attrs, [:object, :title, :override_class_name, :override_class_file])
    |> unique_constraint(:object)
  end
end
