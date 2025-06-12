defmodule Tunez.Music.Album do
  use Ash.Resource, otp_app: :tunez, domain: Tunez.Music, data_layer: AshPostgres.DataLayer

  postgres do
    table "albums"
    repo Tunez.Repo

    # create a database index for the foreign key
    references do
      reference :artist, index?: true
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:name, :year_released, :cover_image_url, :artist_id]
    end

    update :update do
      accept [:name, :year_released, :cover_image_url]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
    end

    attribute :year_released, :integer do
      allow_nil? false
    end

    attribute :cover_image_url, :string do
      allow_nil? true
    end

    timestamps()
  end

  relationships do
    belongs_to :artist, Tunez.Music.Artist do
      allow_nil? false
    end
  end
end
