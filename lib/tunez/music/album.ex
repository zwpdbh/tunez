defmodule Tunez.Music.Album do
  use Ash.Resource,
    otp_app: :tunez,
    domain: Tunez.Music,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshGraphql.Resource, AshJsonApi.Resource],
    authorizers: [Ash.Policy.Authorizer]

  graphql do
    type :album
  end

  json_api do
    type "album"
    # allow tracks to be included when reading an album
    # This will allow users to add the `include=tracks` query parameter to their
    # requests to Album-related endpoints, and the track data will be included.
    includes [:tracks]
  end

  postgres do
    table "albums"
    repo Tunez.Repo

    # create a database index for the foreign key
    references do
      reference :artist, index?: true, on_delete: :delete
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:name, :year_released, :cover_image_url]

      # The following is equal to set `:artist_id` in `accept [:name, :year_released, :cover_image_url, :artist_id]`
      argument :artist_id, :uuid, allow_nil?: false
      change manage_relationship(:artist_id, :artist, type: :append_and_remove)

      argument :tracks, {:array, :map}
      # Because the name of the argument and the name of the relationship to be
      # managed are the same (tracks), we can omit one when calling manage_relationship.
      # `order_is_key` take the position of the record in the list,
      # and set it as the value of the attribute we specify which is `:order`
      change manage_relationship(:tracks, type: :direct_control, order_is_key: :order)
    end

    update :update do
      accept [:name, :year_released, :cover_image_url]
      # TODO: fix this to be atomic
      require_atomic? false

      argument :tracks, {:array, :map}
      change manage_relationship(:tracks, type: :direct_control, order_is_key: :order)
    end
  end

  policies do
    bypass actor_attribute_equals(:role, :admin) do
      authorize_if always()
    end

    policy action_type(:read) do
      authorize_if always()
    end

    policy action(:create) do
      authorize_if actor_attribute_equals(:role, :editor)
    end

    # such that only the user who created the album can update or destroy it
    policy action([:update, :destroy]) do
      authorize_if expr(^actor(:role) == :editor and created_by_id == ^actor(:id))
    end
  end

  changes do
    change relate_actor(:created_by, allow_nil?: true), on: [:create]
    change relate_actor(:updated_by, allow_nil?: true)
  end

  validations do
    validate numericality(:year_released,
               greater_than: 1950,
               less_than_or_equal_to: &__MODULE__.next_year/0
             ),
             where: [present(:year_released)],
             message: "must be between 1950 and next year"

    validate match(
               :cover_image_url,
               ~r"(^https://|/images/).+(\.png|\.jpg)$"
             ),
             where: [changing(:cover_image_url)],
             message: "must start with https:// or /images/"
  end

  def next_year, do: Date.utc_today().year + 1

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :year_released, :integer do
      allow_nil? false
      public? true
    end

    attribute :cover_image_url, :string do
      allow_nil? true
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :artist, Tunez.Music.Artist do
      allow_nil? false
    end

    belongs_to :created_by, Tunez.Accounts.User
    belongs_to :updated_by, Tunez.Accounts.User

    has_many :tracks, Tunez.Music.Track do
      sort order: :asc
      public? true
    end
  end

  calculations do
    calculate :years_ago, :integer, expr(2025 - year_released)

    #  Tunez.Music.get_artist_by_id(«uuid», load: [albums: [:string_years_ago]])
    calculate :string_year_ago,
              :string,
              expr("wow, this was released " <> years_ago <> " years ago!")

    calculate :duration, :string, Tunez.Music.Calculations.SecondsToMinutes
  end

  aggregates do
    sum :duration_seconds, :tracks, :duration_seconds
  end

  # After defining identity, do not forget:
  # first, `mix ash.codegen update_<your_identity>`.
  # then, `mix ash.migrate`
  identities do
    identity :unique_album_name_per_artist, [:name, :artist_id],
      message: "already exists for this artist"
  end
end
