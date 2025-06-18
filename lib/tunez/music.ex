defmodule Tunez.Music do
  use Ash.Domain,
    otp_app: :tunez,
    extensions: [AshGraphql.Domain, AshJsonApi.Domain, AshPhoenix]

  graphql do
    queries do
      get Tunez.Music.Artist, :get_artist_by_id, :read
      list Tunez.Music.Artist, :search_artists, :search
    end

    mutations do
      create Tunez.Music.Artist, :create_artist, :create
      update Tunez.Music.Artist, :update_artist, :update
      destroy Tunez.Music.Artist, :destroy_artist, :destroy

      create Tunez.Music.Album, :create_album, :create
      update Tunez.Music.Album, :update_album, :update
      destroy Tunez.Music.Album, :destroy_album, :destroy
    end
  end

  json_api do
    routes do
      base_route "/artists", Tunez.Music.Artist do
        get :read
        index :search
        post :create
        patch :update
        delete :destroy

        # for usage like:
        # http://localhost:4000/api/json/artists/[id]/albums.
        related :albums, :read, primary?: true
      end

      base_route "/albums", Tunez.Music.Album do
        post :create
        patch :update
        delete :destroy
      end
    end
  end

  forms do
    form :create_album, args: [:artist_id]
  end

  resources do
    resource Tunez.Music.Artist do
      define :create_artist, action: :create

      define :read_artists, action: :read
      define :get_artist_by_id, action: :read, get_by: :id
      define :update_artist, action: :update
      define :destroy_artist, action: :destroy

      define :search_artists,
        action: :search,
        args: [:query],
        default_options: [load: [:album_count, :latest_album_year_released, :cover_image_url]]
    end

    resource Tunez.Music.Album do
      define :create_album, action: :create
      define :get_album_by_id, action: :read, get_by: :id
      define :update_album, action: :update
      define :destroy_album, action: :destroy
    end

    resource Tunez.Music.Track

    # resource Tunez.Music.ArtistFollower do
    #   define :follow_artist, action: :create, args: [:artist]
    # end

    # improved version using custom inputs
    resource Tunez.Music.ArtistFollower do
      define :follow_artist do
        action :create
        args [:artist]

        # use custom inputs: customize how we transform the input to the resource's action
        # https://ash-project.github.io/ash/code-interfaces.html#customizing-the-generated-function
        custom_input :artist, :struct do
          constraints instance_of: Tunez.Music.Artist
          transform to: :artist_id, using: & &1.id
        end
      end
    end
  end

  def play do
    Tunez.Music.create_artist(%{
      name: "Valkyrie's Fury",
      biography: "A power metal band hailing from Tallinn, Estonia"
    })
  end
end
