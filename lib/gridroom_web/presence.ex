defmodule GridroomWeb.Presence do
  @moduledoc """
  Tracks user presence on the grid.
  """

  use Phoenix.Presence,
    otp_app: :gridroom,
    pubsub_server: Gridroom.PubSub

  alias Gridroom.Accounts.User

  @topic "grid:presence"

  def track_user(pid, %User{} = user) do
    track(pid, @topic, user.id, %{
      user_id: user.id,
      glyph_shape: user.glyph_shape,
      glyph_color: user.glyph_color,
      x: 0,
      y: 0,
      joined_at: System.system_time(:second)
    })
  end

  def update_position(pid, %User{} = user, x, y) do
    update(pid, @topic, user.id, fn meta ->
      %{meta | x: x, y: y}
    end)
  end

  def list_users do
    list(@topic)
  end

  def handle_diff(users, %{joins: joins, leaves: leaves}) do
    users =
      Enum.reduce(joins, users, fn {id, %{metas: [meta | _]}}, acc ->
        Map.put(acc, id, meta)
      end)

    Enum.reduce(leaves, users, fn {id, _}, acc ->
      Map.delete(acc, id)
    end)
  end

  def subscribe do
    Phoenix.PubSub.subscribe(Gridroom.PubSub, @topic)
  end
end
