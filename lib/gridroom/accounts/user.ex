defmodule Gridroom.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Gridroom.Accounts.Glyphs

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :session_id, :string
    field :username, :string
    field :hashed_password, :string
    field :password, :string, virtual: true, redact: true
    field :glyph_id, :integer
    # Legacy fields - kept for backwards compatibility during migration
    field :glyph_shape, :string, default: "circle"
    field :glyph_color, :string, default: "#D4A574"
    field :resonance, :integer, default: 50
    field :bucket_ids, {:array, :binary_id}, default: []
    field :created_node_ids, {:array, :binary_id}, default: []

    has_many :messages, Gridroom.Grid.Message

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for anonymous session-based users.
  """
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:session_id, :glyph_id])
    |> validate_required([:session_id])
    |> validate_number(:glyph_id, greater_than_or_equal_to: 0, less_than: Glyphs.count())
    |> unique_constraint(:session_id)
  end

  @doc """
  Changeset for user registration with username and password.
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :password, :glyph_id])
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
      glyph_id: Glyphs.random_id()
    }
  end

  @doc """
  Returns the glyph name for this user.
  """
  def glyph_name(%__MODULE__{glyph_id: glyph_id}) when is_integer(glyph_id) do
    Glyphs.name(glyph_id)
  end
  def glyph_name(_), do: "unknown"

  @doc """
  Returns the display name for this user's glyph (e.g., "the goat", "specimen-alpha").
  """
  def glyph_display_name(%__MODULE__{glyph_id: glyph_id}) when is_integer(glyph_id) do
    Glyphs.display_name(glyph_id)
  end
  def glyph_display_name(_), do: "unknown"

  @doc """
  Returns the glyph color for this user.
  """
  def glyph_color(%__MODULE__{glyph_id: glyph_id}) when is_integer(glyph_id) do
    Glyphs.color(glyph_id)
  end
  def glyph_color(_), do: "hsl(30, 20%, 45%)"

  @doc """
  Changeset for updating bucket IDs.
  """
  def bucket_changeset(user, attrs) do
    user
    |> cast(attrs, [:bucket_ids])
  end

  @doc """
  Changeset for updating created node IDs.
  """
  def created_nodes_changeset(user, attrs) do
    user
    |> cast(attrs, [:created_node_ids])
  end
end
