defmodule Tunez.Music.Artist do
  use Ash.Resource,
    otp_app: :tunez,
    domain: Tunez.Music,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshGraphql.Resource, AshJsonApi.Resource],
    authorizers: [Ash.Policy.Authorizer]

  graphql do
    type :artist

    # To customize the list of fields that we can filter on.
    filterable_fields [
      :album_count,
      :cover_image_url,
      :inserted_at,
      :latest_album_year_released,
      :updated_at
    ]
  end

  json_api do
    type "artist"
    # includes [:albums] (previously defined to just include albums when readh artist)
    # With this config, users can request either albums to be included for an artist
    # with include=albums in the query string, or albums and their tracks with include=albums.tracks.
    includes albums: [:tracks]
    # disable the generated filtering in the open_api
    derive_filter? false
  end

  postgres do
    table "artists"
    repo Tunez.Repo

    custom_indexes do
      index "name gin_trgm_ops", name: "artist_name_gin_index", using: "GIN"
    end
  end

  resource do
    description "A person or group of people that makes and releases music."
  end

  actions do
    create :create do
      accept [:name, :biography]
    end

    read :read do
      primary? true
    end

    read :search do
      description "List Artists, optionally filtering by name."

      argument :query, :ci_string do
        description "Return only artists with names including the given value."
        constraints allow_empty?: true
        default ""
      end

      filter expr(contains(name, ^arg(:query)))

      pagination offset?: true, default_limit: 12
    end

    update :update do
      require_atomic? false

      accept [:name, :biography]

      # TODO: rewrite change atomically
      change Tunez.Music.Changes.UpdatePreviousNames,
        where: [changing(:name)]
    end

    destroy :destroy do
    end
  end

  policies do
    bypass actor_attribute_equals(:role, :admin) do
      authorize_if always()
    end

    policy action_type(:read) do
      authorize_if always()
    end

    policy action(:update) do
      authorize_if actor_attribute_equals(:role, :editor)
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :biography, :string

    attribute :previous_names, {:array, :string} do
      default []
      public? true
    end

    create_timestamp :inserted_at, public?: true
    update_timestamp :updated_at, public?: true
  end

  relationships do
    has_many :albums, Tunez.Music.Album do
      sort year_released: :desc
      public? true
    end

    has_many :follower_relationships, Tunez.Music.ArtistFollower

    many_to_many :followers, Tunez.Accounts.User do
      join_relationship :follower_relationships
      destination_attribute_on_join_resource :follower_id
    end

    belongs_to :created_by, Tunez.Accounts.User
    belongs_to :updated_by, Tunez.Accounts.User
  end

  calculations do
    # Tunez.Music.search_artists("a", load: [:album_count])
    # calculate :album_count, :integer, expr(count(albums))
    # Tunez.Music.search_artists("a", load: [:latest_album_year_released])
    # calculate :latest_album_year_released, :integer, expr(first(albums, field: :year_released))
    # calculate :cover_image_url, :string, expr(first(albumns, field: :cover_image_url))

    calculate :followed_by_me,
              :boolean,
              expr(exists(follower_relationships, follower_id == ^actor(:id)))
  end

  # https://hexdocs.pm/ash/dsl-ash-resource.html#aggregates
  aggregates do
    # calculate :album_count, :integer, expr(count(albums))
    count :album_count, :albums do
      public? true
    end

    # calculate :latest_album_year_released, :integer, expr(first(albums, field: :year_released))
    first :latest_album_year_released, :albums, :year_released do
      public? true
    end

    # calculate :cover_image_url, :string, expr(first(albumns, field: :cover_image_url))
    first :cover_image_url, :albums, :cover_image_url
  end
end
