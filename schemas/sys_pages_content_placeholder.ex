defmodule DeeperHub.Schema.SysPagesContentPlaceholder do
  @moduledoc """
  Schema para representação de sys_pages_content_placeholders no sistema

  Este schema armazena as informações de um sys_pages_content_placeholder.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_pages_content_placeholders" do
    field :module, :string  # varchar(32)
    field :title, :string  # varchar(255)
    field :template, :string  # varchar(255)
    field :order, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_pages_content_placeholder no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    module: String.t() | nil,
    title: String.t() | nil,
    template: String.t() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_pages_content_placeholder.

  ## Parâmetros 
    - `sys_pages_content_placeholder`: Struct do sys_pages_content_placeholder (pode ser %SysPagesContentPlaceholder{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_pages_content_placeholder \ %__MODULE__{}, attrs) do
    sys_pages_content_placeholder
    |> cast(attrs, [:module, :title, :template, :order])
    |> validate_required([:module, :title, :template, :order])
  end

  @doc """
  Changeset para atualização de um sys_pages_content_placeholder existente.

  ## Parâmetros 
    - `sys_pages_content_placeholder`: Struct do sys_pages_content_placeholder (%SysPagesContentPlaceholder{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_pages_content_placeholder \ %__MODULE__{}, attrs) do
    sys_pages_content_placeholder
    |> cast(attrs, [:module, :title, :template, :order])
  end
end
