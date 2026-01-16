defmodule Gridroom.Accounts do
  @moduledoc """
  The Accounts context - manages session-based users.
  """

  alias Gridroom.Repo
  alias Gridroom.Accounts.User

  def get_user!(id), do: Repo.get!(User, id)

  def get_user(id), do: Repo.get(User, id)

  def get_user_by_session(session_id) do
    Repo.get_by(User, session_id: session_id)
  end

  def get_or_create_user(session_id) do
    case get_user_by_session(session_id) do
      nil ->
        user = User.new_with_random_glyph(session_id)
        Repo.insert(user)

      user ->
        {:ok, user}
    end
  end

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end
end
