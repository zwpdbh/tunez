defmodule Tunez.Accounts.Changes.SendNewAlbumNotifications do
  use Ash.Resource.Change

  # @impl true
  # def change(changeset, _opts, _context) do
  #   Ash.Changeset.after_action(changeset, fn _changeset, album ->
  #     album = Ash.load!(album, artist: [:follower_relationships])

  #     album.artist.follower_relationships
  #     |> Enum.map(fn %{follower_id: follower_id} ->
  #       %{album_id: album.id, user_id: follower_id}
  #     end)
  #     |> Ash.bulk_create!(Tunez.Accounts.Notification, :create, authorize?: false)

  #     {:ok, album}
  #   end)
  # end

  # compare with above version, this one is using steam
  @impl true
  def change(changeset, _opts, _context) do
    changeset
    |> Ash.Changeset.after_action(fn _changeset, album ->
      Tunez.Music.followers_for_artist!(album.artist_id, stream?: true)
      |> Stream.map(fn %{follower_id: follower_id} ->
        %{album_id: album.id, user_id: follower_id}
      end)
      |> Ash.bulk_create!(Tunez.Accounts.Notification, :create, authorize?: false, notify?: true)

      {:ok, album}
    end)
  end

  @impl true
  def atomic(changeset, opts, context) do
    {:ok, change(changeset, opts, context)}
  end
end
