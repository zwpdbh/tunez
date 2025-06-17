defmodule Tunez.Music.Track do
  use Ash.Resource,
    otp_app: :tunez,
    domain: Tunez.Music,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

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
    end

    update :update do
      primary? true
      accept [:order, :name, :duration_seconds]
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
    prepare build(load: [:number])
  end

  attributes do
    uuid_primary_key :id

    attribute :order, :integer do
      allow_nil? false
    end

    attribute :name, :string do
      allow_nil? false
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
    calculate :number, :integer, expr(order + 1)
  end
end
