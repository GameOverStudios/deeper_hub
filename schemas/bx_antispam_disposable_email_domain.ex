defmodule DeeperHub.Schema.BxAntispamDisposableEmailDomain do
  @moduledoc """
  Schema para representação de bx_antispam_disposable_email_domains no sistema

  Este schema armazena as informações de um bx_antispam_disposable_email_domain.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_antispam_disposable_email_domains" do
    field :domain, :string  # varchar(255)
    field :list, Ecto.Enum, values: [:blacklist, :custom_blacklist, :whitelist, :custom_whitelist], default: "custom_blacklist"  # enum('blacklist','custom_blacklist','whitelist','custom_whitelist')

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_antispam_disposable_email_domain no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    domain: String.t() | nil,
    list: :blacklist | :custom_blacklist | :whitelist | :custom_whitelist | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_antispam_disposable_email_domain.

  ## Parâmetros 
    - `bx_antispam_disposable_email_domain`: Struct do bx_antispam_disposable_email_domain (pode ser %BxAntispamDisposableEmailDomain{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_antispam_disposable_email_domain \ %__MODULE__{}, attrs) do
    bx_antispam_disposable_email_domain
    |> cast(attrs, [:domain, :list])
    |> validate_required([:domain])
    |> unique_constraint(:domain)
  end

  @doc """
  Changeset para atualização de um bx_antispam_disposable_email_domain existente.

  ## Parâmetros 
    - `bx_antispam_disposable_email_domain`: Struct do bx_antispam_disposable_email_domain (%BxAntispamDisposableEmailDomain{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_antispam_disposable_email_domain \ %__MODULE__{}, attrs) do
    bx_antispam_disposable_email_domain
    |> cast(attrs, [:domain, :list])
    |> unique_constraint(:domain)
  end
end
