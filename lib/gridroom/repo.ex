defmodule Gridroom.Repo do
  use Ecto.Repo,
    otp_app: :gridroom,
    adapter: Ecto.Adapters.Postgres
end
