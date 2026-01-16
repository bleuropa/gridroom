defmodule Gridroom.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @glyph_shapes ~w(circle triangle square diamond hexagon pentagon)
  @glyph_colors ~w(#D4A574 #8B7355 #A0522D #CD853F #DEB887 #BC8F8F)

  schema "users" do
    field :session_id, :string
    field :glyph_shape, :string, default: "circle"
    field :glyph_color, :string, default: "#D4A574"

    has_many :messages, Gridroom.Grid.Message

    timestamps(type: :utc_datetime)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:session_id, :glyph_shape, :glyph_color])
    |> validate_required([:session_id])
    |> validate_inclusion(:glyph_shape, @glyph_shapes)
    |> unique_constraint(:session_id)
  end

  @doc """
  Creates a new user with a random glyph.
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
