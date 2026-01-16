defmodule GridroomWeb.UserSessionController do
  use GridroomWeb, :controller

  alias Gridroom.Accounts

  def create(conn, %{"username" => username, "password" => password}) do
    case Accounts.authenticate_user(username, password) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Welcome back, #{user.username}!")
        |> redirect(to: ~p"/")

      {:error, :invalid_credentials} ->
        conn
        |> put_flash(:error, "Invalid username or password")
        |> redirect(to: ~p"/login")
    end
  end

  def register(conn, %{"user" => user_params}) do
    # Check for anonymous user to inherit glyph
    anonymous_user =
      case get_session(conn, :_csrf_token) do
        nil -> nil
        token -> Accounts.get_user_by_session(token)
      end

    case Accounts.register_user(user_params, anonymous_user: anonymous_user) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Account created! Welcome, #{user.username}.")
        |> redirect(to: ~p"/")

      {:error, %Ecto.Changeset{} = changeset} ->
        # Get first error message
        error_msg =
          changeset
          |> Ecto.Changeset.traverse_errors(fn {msg, _opts} -> msg end)
          |> Enum.map(fn {field, msgs} -> "#{field} #{List.first(msgs)}" end)
          |> List.first()

        conn
        |> put_flash(:error, error_msg || "Registration failed")
        |> redirect(to: ~p"/register")
    end
  end

  def delete(conn, _params) do
    conn
    |> delete_session(:user_id)
    |> put_flash(:info, "Logged out successfully.")
    |> redirect(to: ~p"/")
  end
end
