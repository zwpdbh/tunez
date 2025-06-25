defmodule Tunez.Music.Changes.UpdatePreviousNames do
  use Ash.Resource.Change

  # @impl true
  # def change(changeset, _opts, _context) do
  #   # The anonymous function set as the before_action would only run once
  #   Ash.Changeset.before_action(changeset, fn changeset ->
  #     new_name = Ash.Changeset.get_attribute(changeset, :name)
  #     previous_name = Ash.Changeset.get_data(changeset, :name)
  #     previous_names = Ash.Changeset.get_data(changeset, :previous_names)

  #     names =
  #       [previous_name | previous_names]
  #       |> Enum.uniq()
  #       |> Enum.reject(fn name -> name == new_name end)

  #     Ash.Changeset.change_attribute(changeset, :previous_names, names)
  #   end)
  # end

  @impl true
  def atomic(_changeset, _opts, _context) do
    {:atomic,
     %{
       previous_names:
         {:atomic,
          expr(
            fragment(
              "array_remove(array_prepend(?, ?), ?)",
              name,
              previous_names,
              ^atomic_ref(:name)
            )
          )}
     }}
  end
end
