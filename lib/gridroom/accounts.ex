defmodule Gridroom.Accounts do
  @moduledoc """
  The Accounts context - manages users (both anonymous and registered).
  """

  alias Gridroom.Repo
  alias Gridroom.Accounts.User

  ## User queries

  def get_user!(id), do: Repo.get!(User, id)

  def get_user(id), do: Repo.get(User, id)

  def get_user_by_session(session_id) do
    Repo.get_by(User, session_id: session_id)
  end

  def get_user_by_username(username) when is_binary(username) do
    Repo.get_by(User, username: username)
  end

  ## Anonymous user creation

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

  ## Registration

  @doc """
  Registers a new user with username and password.
  Optionally preserves glyph from an existing anonymous user.
  """
  def register_user(attrs, opts \\ []) do
    # If an anonymous user is provided, inherit their glyph
    attrs =
      case Keyword.get(opts, :anonymous_user) do
        %User{glyph_shape: shape, glyph_color: color} ->
          Map.merge(%{"glyph_shape" => shape, "glyph_color" => color}, attrs)

        _ ->
          # New user gets random glyph
          Map.merge(
            %{
              "glyph_shape" => Enum.random(User.glyph_shapes()),
              "glyph_color" => Enum.random(User.glyph_colors())
            },
            attrs
          )
      end

    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns a changeset for tracking user registration changes.
  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs)
  end

  ## Authentication

  @doc """
  Authenticates a user by username and password.
  """
  def authenticate_user(username, password)
      when is_binary(username) and is_binary(password) do
    user = get_user_by_username(username)

    if User.valid_password?(user, password) do
      {:ok, user}
    else
      {:error, :invalid_credentials}
    end
  end
end
