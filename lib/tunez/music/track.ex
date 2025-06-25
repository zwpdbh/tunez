defmodule Tunez.Music.Track do
  use Ash.Resource,
    otp_app: :tunez,
    domain: Tunez.Music,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshGraphql.Resource, AshJsonApi.Resource]

  graphql do
    type :track
  end

  json_api do
    type "track"
    # This makes every response will contain these fields
    # This must be done, because only public attributes will be fetched and returned via JSON API. However, the only public attribute we have is `name`
    default_fields [:number, :name, :duration]
  end

  postgres do
    table "tracks"
    repo Tunez.Repo

    references do
      # Customize reference to the album table such that
      # if an album is deleted, all associated tracks will be deleted too.
      reference :album, index?: true, on_delete: :delete
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:order, :name, :duration_seconds, :album_id]

      argument :duration, :string, allow_nil?: false
      change Tunez.Music.Changes.MinutesToSeconds, only_when_valid?: true
    end

    update :update do
      primary? true
      accept [:order, :name, :duration_seconds]

      # Instead of accepting `duration_seconds` attribute directly,
      # we could pass in the formatted version of the duration as an argument,
      # and then use a change to process that argument.
      # This means, when ever update is called,
      # :duration in changeset -> Tunez.Music.Changes.MinutesToSeconds -> :duration_seconds in changeset
      argument :duration, :string, allow_nil?: false
      change Tunez.Music.Changes.MinutesToSeconds, only_when_valid?: true
      require_atomic? false
    end
  end

  policies do
    # “if tracks are being read/created/updated/deleted through
    # a :tracks relationship on the Tunez.Music.Album resource, then the request is authorized”.
    policy always() do
      authorize_if accessing_from(Tunez.Music.Album, :tracks)
      authorize_if action_type(:read)
    end
  end

  preparations do
    # always want this number calculation loaded, when loading track data
    prepare build(load: [:number, :duration])
  end

  attributes do
    uuid_primary_key :id

    attribute :order, :integer do
      allow_nil? false
    end

    attribute :name, :string do
      allow_nil? false

      public? true
    end

    attribute :duration_seconds, :integer do
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    belongs_to :album, Tunez.Music.Album do
      allow_nil? false
    end
  end

  calculations do
    # represent the order in the track list, increase from order + 1 because order is indexed from 0
    calculate :number, :integer, expr(order + 1) do
      public? true
    end

    calculate :duration, :string, Tunez.Music.Calculations.SecondsToMinutes do
      public? true
    end
  end
end
