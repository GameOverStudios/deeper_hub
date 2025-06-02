defmodule DeeperHub.Schema.SysObjectsRs do
  @moduledoc """
  Schema para representação de sys_objects_rss no sistema

  Este schema armazena as informações de um sys_objects_rs.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_objects_rss" do
    field :object, :string  # varchar(64)
    field :class_name, :string, default: ""  # varchar(32)
    field :class_file, :string, default: ""  # varchar(256)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_objects_rs no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object: String.t() | nil,
    class_name: String.t() | nil,
    class_file: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_objects_rs.

  ## Parâmetros 
    - `sys_objects_rs`: Struct do sys_objects_rs (pode ser %SysObjectsRs{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_objects_rs \ %__MODULE__{}, attrs) do
    sys_objects_rs
    |> cast(attrs, [:object, :class_name, :class_file])
    |> validate_required([:object, :class_name, :class_file])
  end

  @doc """
  Changeset para atualização de um sys_objects_rs existente.

  ## Parâmetros 
    - `sys_objects_rs`: Struct do sys_objects_rs (%SysObjectsRs{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_objects_rs \ %__MODULE__{}, attrs) do
    sys_objects_rs
    |> cast(attrs, [:object, :class_name, :class_file])
  end
end
