defmodule DeeperHub.Schema.SysSeoUriRewrite do
  @moduledoc """
  Schema para representação de sys_seo_uri_rewrites no sistema

  Este schema armazena as informações de um sys_seo_uri_rewrite.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_seo_uri_rewrites" do
    field :uri_orig, :string  # varchar(255)
    field :uri_rewrite, :string  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_seo_uri_rewrite no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    uri_orig: String.t() | nil,
    uri_rewrite: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_seo_uri_rewrite.

  ## Parâmetros 
    - `sys_seo_uri_rewrite`: Struct do sys_seo_uri_rewrite (pode ser %SysSeoUriRewrite{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_seo_uri_rewrite \ %__MODULE__{}, attrs) do
    sys_seo_uri_rewrite
    |> cast(attrs, [:uri_orig, :uri_rewrite])
    |> validate_required([:uri_orig, :uri_rewrite])
    |> unique_constraint(:uri_orig)
    |> unique_constraint(:uri_rewrite)
  end

  @doc """
  Changeset para atualização de um sys_seo_uri_rewrite existente.

  ## Parâmetros 
    - `sys_seo_uri_rewrite`: Struct do sys_seo_uri_rewrite (%SysSeoUriRewrite{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_seo_uri_rewrite \ %__MODULE__{}, attrs) do
    sys_seo_uri_rewrite
    |> cast(attrs, [:uri_orig, :uri_rewrite])
    |> unique_constraint(:uri_orig)
    |> unique_constraint(:uri_rewrite)
  end
end
