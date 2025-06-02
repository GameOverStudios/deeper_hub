defmodule DeeperHub.Schema.SysPermalink do
  @moduledoc """
  Schema para representação de sys_permalinks no sistema

  Este schema armazena as informações de um sys_permalink.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_permalinks" do
    field :standard, :string, default: ""  # varchar(128)
    field :permalink, :string, default: ""  # varchar(128)
    field :check, :string, default: ""  # varchar(64)
    field :compare_by_prefix, :integer, default: 0  # tinyint(4)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_permalink no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    standard: String.t() | nil,
    permalink: String.t() | nil,
    check: String.t() | nil,
    compare_by_prefix: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_permalink.

  ## Parâmetros 
    - `sys_permalink`: Struct do sys_permalink (pode ser %SysPermalink{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_permalink \ %__MODULE__{}, attrs) do
    sys_permalink
    |> cast(attrs, [:standard, :permalink, :check, :compare_by_prefix])
    |> validate_required([:standard, :permalink, :check])
  end

  @doc """
  Changeset para atualização de um sys_permalink existente.

  ## Parâmetros 
    - `sys_permalink`: Struct do sys_permalink (%SysPermalink{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_permalink \ %__MODULE__{}, attrs) do
    sys_permalink
    |> cast(attrs, [:standard, :permalink, :check, :compare_by_prefix])
  end
end
