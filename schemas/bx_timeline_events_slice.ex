defmodule DeeperHub.Schema.BxTimelineEventsSlice do
  @moduledoc """
  Schema para representação de bx_timeline_events_slices no sistema

  Este schema armazena as informações de um bx_timeline_events_slice.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_timeline_events_slice" do
    field :owner_id, :integer, default: 0  # int(11)
    field :system, :integer, default: 1  # tinyint(4)
    field :type, :string  # varchar(255)
    field :action, :string  # varchar(255)
    field :object_id, :integer, default: 0  # int(11)
    field :object_owner_id, :integer, default: 0  # int(11)
    field :object_privacy_view, :string, default: "3"  # varchar(16)
    field :object_cf, :integer, default: 1  # int(11)
    field :content, :string  # text
    field :source, :string, default: ""  # varchar(32)
    field :title, :string  # varchar(255)
    field :description, :string  # text
    field :labels, :string  # text
    field :location, :string  # text
    field :views, :integer, default: 0  # int(11) unsigned
    field :rate, :float, default: 0  # float
    field :votes, :integer, default: 0  # int(11) unsigned
    field :rrate, :float, default: 0  # float
    field :rvotes, :integer, default: 0  # int(11)
    field :score, :integer, default: 0  # int(11)
    field :sc_up, :integer, default: 0  # int(11)
    field :sc_down, :integer, default: 0  # int(11)
    field :comments, :integer, default: 0  # int(11) unsigned
    field :reports, :integer, default: 0  # int(11) unsigned
    field :reposts, :integer, default: 0  # int(11) unsigned
    field :date, :integer, default: 0  # int(11)
    field :published, :integer, default: 0  # int(11)
    field :reacted, :integer, default: 0  # int(11)
    field :status, Ecto.Enum, values: [:active, :awaiting, :failed, :hidden, :deleted], default: "active"  # enum('active','awaiting','failed','hidden','deleted')
    field :status_admin, Ecto.Enum, values: [:active, :hidden, :pending], default: "active"  # enum('active','hidden','pending')
    field :active, :integer, default: 1  # tinyint(4)
    field :pinned, :integer, default: 0  # int(11)
    field :sticked, :integer, default: 0  # int(11)
    field :promoted, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_timeline_events_slice no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    owner_id: integer() | nil,
    system: integer() | nil,
    type: String.t() | nil,
    action: String.t() | nil,
    object_id: integer() | nil,
    object_owner_id: integer() | nil,
    object_privacy_view: String.t() | nil,
    object_cf: integer() | nil,
    content: String.t() | nil,
    source: String.t() | nil,
    title: String.t() | nil,
    description: String.t() | nil,
    labels: String.t() | nil,
    location: String.t() | nil,
    views: integer() | nil,
    rate: float() | nil,
    votes: integer() | nil,
    rrate: float() | nil,
    rvotes: integer() | nil,
    score: integer() | nil,
    sc_up: integer() | nil,
    sc_down: integer() | nil,
    comments: integer() | nil,
    reports: integer() | nil,
    reposts: integer() | nil,
    date: integer() | nil,
    published: integer() | nil,
    reacted: integer() | nil,
    status: :active | :awaiting | :failed | :hidden | :deleted | nil,
    status_admin: :active | :hidden | :pending | nil,
    active: integer() | nil,
    pinned: integer() | nil,
    sticked: integer() | nil,
    promoted: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_timeline_events_slice.

  ## Parâmetros 
    - `bx_timeline_events_slice`: Struct do bx_timeline_events_slice (pode ser %BxTimelineEventsSlice{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_timeline_events_slice \ %__MODULE__{}, attrs) do
    bx_timeline_events_slice
    |> cast(attrs, [:owner_id, :system, :type, :action, :object_id, :object_owner_id, :object_privacy_view, :object_cf, :content, :source, :title, :description, :labels, :location, :views, :rate, :votes, :rrate, :rvotes, :score, :sc_up, :sc_down, :comments, :reports, :reposts, :date, :published, :reacted, :status, :status_admin, :active, :pinned, :sticked, :promoted])
    |> validate_required([:type, :action, :content, :source, :title, :description, :labels, :location])
  end

  @doc """
  Changeset para atualização de um bx_timeline_events_slice existente.

  ## Parâmetros 
    - `bx_timeline_events_slice`: Struct do bx_timeline_events_slice (%BxTimelineEventsSlice{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_timeline_events_slice \ %__MODULE__{}, attrs) do
    bx_timeline_events_slice
    |> cast(attrs, [:owner_id, :system, :type, :action, :object_id, :object_owner_id, :object_privacy_view, :object_cf, :content, :source, :title, :description, :labels, :location, :views, :rate, :votes, :rrate, :rvotes, :score, :sc_up, :sc_down, :comments, :reports, :reposts, :date, :published, :reacted, :status, :status_admin, :active, :pinned, :sticked, :promoted])
  end
end
