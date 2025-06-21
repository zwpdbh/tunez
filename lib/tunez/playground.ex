defmodule Tunez.Playground do
  def assign_user_role(username, role) do
    # first get the user match the username,
    # then assign that user with role
    {:ok, users} = Tunez.Accounts.list_users(authorize?: false)

    username = String.downcase(username)

    users
    |> Enum.find(fn each ->
      each.email.string =~ username
    end)
    |> then(fn user ->
      Tunez.Accounts.set_user_role(user, role, authorize?: false)
    end)
  end

  def set_user_to_editor(username) do
    assign_user_role(username, :editor)
  end

  def set_user_to_admin(username) do
    assign_user_role(username, :admin)
  end
end
