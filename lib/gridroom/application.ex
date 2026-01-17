defmodule Gridroom.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GridroomWeb.Telemetry,
      Gridroom.Repo,
      {DNSCluster, query: Application.get_env(:gridroom, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Gridroom.PubSub},
      # Presence for tracking users on the grid
      GridroomWeb.Presence,
      # Folder topic scheduler (daily fetch per folder)
      Gridroom.Grok.FolderScheduler,
      # Start to serve requests, typically the last entry
      GridroomWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Gridroom.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GridroomWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
