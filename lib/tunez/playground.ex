defmodule Tunez.Playground do
  def assign_user() do
    # first get the user match the username,
    # then assign that user with role
    {:ok, users} = Tunez.Accounts.list_users(authorize?: false)

    users
    # |> Enum.find(fn each -> nil end)
  end
end
