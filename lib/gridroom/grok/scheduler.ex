defmodule Gridroom.Grok.Scheduler do
  @moduledoc """
  GenServer that periodically fetches trends and creates nodes.

  Controlled by the `:grok` config:
  - `enabled: true/false` - Whether to run the scheduler
  - `schedule_interval_ms` - How often to check for trends (default: 4 hours)
  """

  use GenServer

  alias Gridroom.Grok.{Client, NodeGenerator}

  require Logger

  # Public API

  @doc """
  Start the scheduler.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Manually trigger a trend fetch and node generation.
  Useful for testing or admin actions.
  """
  def trigger_now do
    GenServer.cast(__MODULE__, :trigger_now)
  end

  @doc """
  Check if the scheduler is enabled.
  """
  def enabled? do
    Client.enabled?()
  end

  @doc """
  Get the current scheduler status.
  """
  def status do
    GenServer.call(__MODULE__, :status)
  end

  # GenServer callbacks

  @impl true
  def init(_opts) do
    state = %{
      last_run: nil,
      last_result: nil,
      runs_count: 0
    }

    # Schedule first run if enabled
    if Client.enabled?() do
      schedule_next_run()
      Logger.info("Grok trend scheduler started")
    else
      Logger.info("Grok trend scheduler disabled (no API key or disabled in config)")
    end

    {:ok, state}
  end

  @impl true
  def handle_cast(:trigger_now, state) do
    Logger.info("Grok scheduler: trigger_now called, enabled=#{Client.enabled?()}")
    new_state = do_fetch_and_generate(state)
    {:noreply, new_state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    status = %{
      enabled: Client.enabled?(),
      last_run: state.last_run,
      last_result: state.last_result,
      runs_count: state.runs_count,
      next_run_in_ms: get_interval()
    }

    {:reply, status, state}
  end

  @impl true
  def handle_info(:scheduled_run, state) do
    new_state =
      if Client.enabled?() do
        do_fetch_and_generate(state)
      else
        state
      end

    # Schedule next run
    schedule_next_run()

    {:noreply, new_state}
  end

  # Private functions

  defp do_fetch_and_generate(state) do
    Logger.info("Running trend fetch and node generation...")

    result =
      case NodeGenerator.generate_trend_nodes(max_nodes: 3) do
        {:ok, nodes} ->
          {:ok, length(nodes)}

        {:error, reason} ->
          {:error, reason}
      end

    %{
      state
      | last_run: DateTime.utc_now(),
        last_result: result,
        runs_count: state.runs_count + 1
    }
  end

  defp schedule_next_run do
    interval = get_interval()
    Process.send_after(self(), :scheduled_run, interval)
  end

  defp get_interval do
    config = Application.get_env(:gridroom, :grok, [])
    Keyword.get(config, :schedule_interval_ms, :timer.hours(4))
  end
end
