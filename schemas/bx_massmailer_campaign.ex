defmodule DeeperHub.Schema.BxMassmailerCampaign do
  @moduledoc """
  Schema para representação de bx_massmailer_campaigns no sistema

  Este schema armazena as informações de um bx_massmailer_campaign.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_massmailer_campaigns" do
    field :title, :string  # varchar(255)
    field :subject, :string  # varchar(255)
    field :from_name, :string  # varchar(255)
    field :reply_to, :string  # varchar(255)
    field :body, :string  # text
    field :segments, :string  # varchar(255)
    field :author, :integer  # int(11)
    field :added, :integer, default: 0  # int(11)
    field :changed, :integer, default: 0  # int(11)
    field :date_sent, :integer, default: 0  # int(11)
    field :email_list, :string  # text
    field :is_one_per_account, :integer  # smallint(1)
    field :is_track_links, :integer  # smallint(1)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_massmailer_campaign no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    title: String.t() | nil,
    subject: String.t() | nil,
    from_name: String.t() | nil,
    reply_to: String.t() | nil,
    body: String.t() | nil,
    segments: String.t() | nil,
    author: integer() | nil,
    added: integer() | nil,
    changed: integer() | nil,
    date_sent: integer() | nil,
    email_list: String.t() | nil,
    is_one_per_account: integer() | nil,
    is_track_links: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_massmailer_campaign.

  ## Parâmetros 
    - `bx_massmailer_campaign`: Struct do bx_massmailer_campaign (pode ser %BxMassmailerCampaign{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_massmailer_campaign \ %__MODULE__{}, attrs) do
    bx_massmailer_campaign
    |> cast(attrs, [:title, :subject, :from_name, :reply_to, :body, :segments, :author, :added, :changed, :date_sent, :email_list, :is_one_per_account, :is_track_links])
    |> validate_required([:author, :is_one_per_account, :is_track_links])
  end

  @doc """
  Changeset para atualização de um bx_massmailer_campaign existente.

  ## Parâmetros 
    - `bx_massmailer_campaign`: Struct do bx_massmailer_campaign (%BxMassmailerCampaign{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_massmailer_campaign \ %__MODULE__{}, attrs) do
    bx_massmailer_campaign
    |> cast(attrs, [:title, :subject, :from_name, :reply_to, :body, :segments, :author, :added, :changed, :date_sent, :email_list, :is_one_per_account, :is_track_links])
  end
end
