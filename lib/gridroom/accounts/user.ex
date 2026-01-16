defmodule Gridroom.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @glyph_shapes ~w(circle triangle square diamond hexagon pentagon)
  @glyph_colors ~w(#D4A574 #8B7355 #A0522D #CD853F #DEB887 #BC8F8F)

  schema "users" do
    field :session_id, :string
    field :username, :string
    field :hashed_password, :string
    field :password, :string, virtual: true, redact: true
    field :glyph_shape, :string, default: "circle"
    field :glyph_color, :string, default: "#D4A574"

    has_many :messages, Gridroom.Grid.Message

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for anonymous session-based users.
  """
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:session_id, :glyph_shape, :glyph_color])
    |> validate_required([:session_id])
    |> validate_inclusion(:glyph_shape, @glyph_shapes)
    |> unique_constraint(:session_id)
  end

  @doc """
  Changeset for user registration with username and password.
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :password, :glyph_shape, :glyph_color])
    |> validate_username()
    |> validate_password()
  end

  defp validate_username(changeset) do
    changeset
    |> validate_required([:username])
    |> validate_length(:username, min: 3, max: 20)
    |> validate_format(:username, ~r/^[a-zA-Z0-9_]+$/,
      message: "only letters, numbers, and underscores allowed"
    )
    |> unsafe_validate_unique(:username, Gridroom.Repo)
    |> unique_constraint(:username)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 72)
    |> hash_password()
  end

  defp hash_password(changeset) do
    case get_change(changeset, :password) do
      nil ->
        changeset

      password ->
        changeset
        |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
        |> delete_change(:password)
    end
  end

  @doc """
  Verifies the password against the hashed password.
  """
  def valid_password?(%__MODULE__{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    # Prevent timing attacks
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Creates a new anonymous user with a random glyph.
  """
  def new_with_random_glyph(session_id) do
    %__MODULE__{
      session_id: session_id,
      glyph_shape: Enum.random(@glyph_shapes),
      glyph_color: Enum.random(@glyph_colors)
    }
  end

  def glyph_shapes, do: @glyph_shapes
  def glyph_colors, do: @glyph_colors
end
