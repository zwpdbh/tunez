defmodule Tunez.Accounts do
  use Ash.Domain, otp_app: :tunez, extensions: [AshGraphql.Domain, AshJsonApi.Domain]

  graphql do
    mutations do
      create Tunez.Accounts.User, :register_user, :register_with_password
    end

    queries do
      get Tunez.Accounts.User, :sign_in_user, :sign_in_with_password do
        type_name :user_with_token
        # so we don't need to provide id in the query
        identity false
      end
    end
  end

  json_api do
    routes do
      base_route "/users", Tunez.Accounts.User do
        post :register_with_password, route: "/register"

        post :sign_in_with_password do
          route "/sign-in"

          metadata fn _subject, user, _request ->
            %{token: user.__metadata__.token}
          end
        end
      end
    end
  end

  resources do
    resource Tunez.Accounts.Token

    resource Tunez.Accounts.User do
      define :set_user_role, action: :set_role, args: [:role]
      define :get_user_by_id, action: :read, get_by: [:id]
      define :list_users, action: :read
    end

    resource Tunez.Accounts.Notification
  end

  def test_list_users do
    {:ok, users} = Tunez.Accounts.list_users(authorize?: false)
    users
  end

  def test_set_user_role do
    {:ok, [first | _others]} = Tunez.Accounts.list_users(authorize?: false)
    Tunez.Accounts.set_user_role(first, :admin, authorize?: false)
  end
end
