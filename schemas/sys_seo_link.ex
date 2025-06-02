defmodule DeeperHub.Schema.SysSeoLink do
  @moduledoc """
  Schema para representação de sys_seo_links no sistema

  Este schema armazena as informações de um sys_seo_link.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_seo_links" do
    field :module, :string  # varchar(32)
    field :page_uri, :string  # varchar(255)
    field :param_name, :string  # varchar(32)
    field :param_value, :string  # varchar(32)
    field :uri, :string  # varchar(50)
    field :added, :integer  # int(48)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_seo_link no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    module: String.t() | nil,
    page_uri: String.t() | nil,
    param_name: String.t() | nil,
    param_value: String.t() | nil,
    uri: String.t() | nil,
    added: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_seo_link.

  ## Parâmetros 
    - `sys_seo_link`: Struct do sys_seo_link (pode ser %SysSeoLink{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_seo_link \ %__MODULE__{}, attrs) do
    sys_seo_link
    |> cast(attrs, [:module, :page_uri, :param_name, :param_value, :uri, :added])
    |> validate_required([:module, :page_uri, :param_name, :param_value, :uri, :added])
  end

  @doc """
  Changeset para atualização de um sys_seo_link existente.

  ## Parâmetros 
    - `sys_seo_link`: Struct do sys_seo_link (%SysSeoLink{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_seo_link \ %__MODULE__{}, attrs) do
    sys_seo_link
    |> cast(attrs, [:module, :page_uri, :param_name, :param_value, :uri, :added])
  end
end
