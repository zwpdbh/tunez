defmodule Tunez.Music do
  use Ash.Domain,
    otp_app: :tunez,
    extensions: [AshPhoenix]

  resources do
    resource Tunez.Music.Artist do
      define :create_artist, action: :create

      define :read_artists, action: :read
      define :get_artist_by_id, action: :read, get_by: :id
      define :update_artist, action: :update
      define :destroy_artist, action: :destroy
    end

    resource Tunez.Music.Album
  end

  def play do
    Tunez.Music.create_artist(%{
      name: "Valkyrie's Fury",
      biography: "A power metal band hailing from Tallinn, Estonia"
    })
  end
end
