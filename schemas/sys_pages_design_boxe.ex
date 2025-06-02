defmodule DeeperHub.Schema.SysPagesDesignBoxe do
  @moduledoc """
  Schema para representação de sys_pages_design_boxes no sistema

  Este schema armazena as informações de um sys_pages_design_boxe.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_pages_design_boxes" do
    field :title, :string  # varchar(255)
    field :template, :string  # varchar(255)
    field :order, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_pages_design_boxe no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    title: String.t() | nil,
    template: String.t() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_pages_design_boxe.

  ## Parâmetros 
    - `sys_pages_design_boxe`: Struct do sys_pages_design_boxe (pode ser %SysPagesDesignBoxe{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_pages_design_boxe \ %__MODULE__{}, attrs) do
    sys_pages_design_boxe
    |> cast(attrs, [:title, :template, :order])
    |> validate_required([:title, :template, :order])
  end

  @doc """
  Changeset para atualização de um sys_pages_design_boxe existente.

  ## Parâmetros 
    - `sys_pages_design_boxe`: Struct do sys_pages_design_boxe (%SysPagesDesignBoxe{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_pages_design_boxe \ %__MODULE__{}, attrs) do
    sys_pages_design_boxe
    |> cast(attrs, [:title, :template, :order])
  end
end
