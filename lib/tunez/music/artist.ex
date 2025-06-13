defmodule Tunez.Music.Artist do
  use Ash.Resource, otp_app: :tunez, domain: Tunez.Music, data_layer: AshPostgres.DataLayer

  postgres do
    table "artists"
    repo Tunez.Repo

    custom_indexes do
      index "name gin_trgm_ops", name: "artist_name_gin_index", using: "GIN"
    end
  end

  actions do
    create :create do
      accept [:name, :biography]
    end

    read :read do
      primary? true
    end

    read :search do
      argument :query, :ci_string do
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

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :biography, :string

    attribute :previous_names, {:array, :string} do
      default []
    end

    create_timestamp :inserted_at, public?: true
    update_timestamp :updated_at, public?: true
  end

  relationships do
    has_many :albums, Tunez.Music.Album do
      sort year_released: :desc
    end
  end

  calculations do
    # Tunez.Music.search_artists("a", load: [:album_count])
    # calculate :album_count, :integer, expr(count(albums))
    # Tunez.Music.search_artists("a", load: [:latest_album_year_released])
    # calculate :latest_album_year_released, :integer, expr(first(albums, field: :year_released))
    # calculate :cover_image_url, :string, expr(first(albumns, field: :cover_image_url))
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

  def test do
    Tunez.Music.Artist
    |> Ash.Query.for_read(:read)
    |> Ash.Query.sort(name: :asc)
    |> Ash.Query.limit(1)
    |> Ash.read()
  end
end
