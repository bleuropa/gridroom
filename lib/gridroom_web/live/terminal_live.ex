defmodule GridroomWeb.TerminalLive do
  @moduledoc """
  Lumon-inspired terminal interface for discovering discussions.

  Discussions emerge one at a time from the void. You curate through
  rejection - bucket what interests you, dismiss what doesn't.
  """

  use GridroomWeb, :live_view

  alias Gridroom.{Grid, Accounts}
  alias GridroomWeb.Presence

  @emerge_delay_ms 1500   # Slower emergence - more deliberate
  @dismiss_delay_ms 600   # Heavier dismiss - things have weight

  @impl true
  def mount(_params, session, socket) do
    user =
      case session["user_id"] do
        nil ->
          session_id = session["_csrf_token"] || Ecto.UUID.generate()
          {:ok, user} = Accounts.get_or_create_user(session_id)
          user

        user_id ->
          Accounts.get_user(user_id)
      end

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Gridroom.PubSub, "grid:nodes")
      Phoenix.PubSub.subscribe(Gridroom.PubSub, "user:#{user.id}:resonance")
      Presence.track_user(self(), user)
      # Start emergence after mount
      Process.send_after(self(), :emerge_next, @emerge_delay_ms)
    end

    # Load and shuffle nodes for discovery order
    nodes = Grid.list_nodes_with_activity() |> Enum.shuffle()

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:logged_in, user && user.username != nil)
     |> assign(:queue, nodes)  # Remaining nodes to show
     |> assign(:current, nil)  # Currently visible discussion
     |> assign(:current_state, :void)  # :void, :emerging, :visible, :dismissing
     |> assign(:buckets, [])  # Saved discussions (max 6)
     |> assign(:active_bucket, nil)  # Currently viewing bucket index
     |> assign(:view_mode, :discover)  # :discover or :viewing
     |> assign(:drift_seed, :rand.uniform(1000))  # For drift variation
     |> assign(:page_title, "Gridroom")
     |> assign(:show_help, false)}
  end

  # Emergence flow
  @impl true
  def handle_info(:emerge_next, socket) do
    queue = socket.assigns.queue

    if socket.assigns.view_mode == :discover and Enum.any?(queue) do
      [next | rest] = queue
      # Start emerging
      Process.send_after(self(), :emerge_complete, @emerge_delay_ms)

      {:noreply,
       socket
       |> assign(:current, next)
       |> assign(:current_state, :emerging)
       |> assign(:queue, rest)
       |> assign(:drift_seed, :rand.uniform(1000))}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(:emerge_complete, socket) do
    {:noreply, assign(socket, :current_state, :visible)}
  end

  @impl true
  def handle_info(:dismiss_complete, socket) do
    # After dismiss animation, trigger next emergence
    Process.send_after(self(), :emerge_next, @dismiss_delay_ms)
    {:noreply, socket |> assign(:current, nil) |> assign(:current_state, :void)}
  end

  @impl true
  def handle_info({:node_created, node}, socket) do
    # Add new nodes to front of queue
    {:noreply, assign(socket, :queue, [node | socket.assigns.queue])}
  end

  @impl true
  def handle_info({:resonance_changed, _}, socket), do: {:noreply, socket}

  # Keybinds
  @impl true
  def handle_event("keydown", %{"key" => key}, socket) do
    cond do
      # Bucket current discussion (Space or Enter)
      key in [" ", "Enter"] and socket.assigns.current != nil and socket.assigns.view_mode == :discover ->
        bucket_current(socket)

      # Dismiss current discussion (X, Backspace, or Escape in discover mode)
      key in ["x", "X", "Backspace"] and socket.assigns.current != nil and socket.assigns.view_mode == :discover ->
        dismiss_current(socket)

      # Escape - return to discover from viewing, or dismiss in discover
      key == "Escape" ->
        if socket.assigns.view_mode == :viewing do
          {:noreply, socket |> assign(:view_mode, :discover) |> assign(:active_bucket, nil)}
        else
          if socket.assigns.current != nil do
            dismiss_current(socket)
          else
            {:noreply, socket}
          end
        end

      # Number keys 1-6 - enter bucketed discussion directly
      key in ~w(1 2 3 4 5 6) ->
        index = String.to_integer(key) - 1
        buckets = socket.assigns.buckets

        if index < length(buckets) do
          bucket = Enum.at(buckets, index)
          {:noreply, push_navigate(socket, to: "/node/#{bucket.id}")}
        else
          {:noreply, socket}
        end

      # H - toggle help
      key in ["h", "H", "?"] ->
        {:noreply, assign(socket, :show_help, !socket.assigns.show_help)}

      # N - create new (if logged in)
      key in ["n", "N"] and socket.assigns.logged_in ->
        {:noreply, push_navigate(socket, to: ~p"/grid")}  # Use grid for creation for now

      true ->
        {:noreply, socket}
    end
  end

  # Click to bucket
  @impl true
  def handle_event("bucket_current", _params, socket) do
    if socket.assigns.current != nil do
      bucket_current(socket)
    else
      {:noreply, socket}
    end
  end

  # Click to dismiss
  @impl true
  def handle_event("dismiss_current", _params, socket) do
    if socket.assigns.current != nil do
      dismiss_current(socket)
    else
      {:noreply, socket}
    end
  end

  # Click bucket indicator to view
  @impl true
  def handle_event("view_bucket", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    buckets = socket.assigns.buckets

    if index < length(buckets) do
      {:noreply, socket |> assign(:active_bucket, index) |> assign(:view_mode, :viewing)}
    else
      {:noreply, socket}
    end
  end

  # Enter full discussion
  @impl true
  def handle_event("enter_discussion", %{"id" => node_id}, socket) do
    {:noreply, push_navigate(socket, to: "/node/#{node_id}")}
  end

  # Return to discover mode
  @impl true
  def handle_event("return_to_discover", _params, socket) do
    socket = socket |> assign(:view_mode, :discover) |> assign(:active_bucket, nil)
    # Resume emergence if nothing showing
    if socket.assigns.current == nil do
      Process.send_after(self(), :emerge_next, @dismiss_delay_ms)
    end
    {:noreply, socket}
  end

  # Remove from buckets
  @impl true
  def handle_event("remove_bucket", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    buckets = List.delete_at(socket.assigns.buckets, index)

    socket = assign(socket, :buckets, buckets)

    # If removed active bucket, return to discover
    socket = if socket.assigns.active_bucket == index do
      socket |> assign(:view_mode, :discover) |> assign(:active_bucket, nil)
    else
      socket
    end

    {:noreply, socket}
  end

  # Private helpers
  defp bucket_current(socket) do
    current = socket.assigns.current
    buckets = socket.assigns.buckets

    if length(buckets) < 6 do
      new_buckets = buckets ++ [current]
      # Longer delay for keep animation - savoring the moment
      Process.send_after(self(), :dismiss_complete, 800)

      {:noreply,
       socket
       |> assign(:buckets, new_buckets)
       |> assign(:current_state, :keeping)}
    else
      # Buckets full - flash indicator?
      {:noreply, socket}
    end
  end

  defp dismiss_current(socket) do
    Process.send_after(self(), :dismiss_complete, @dismiss_delay_ms)
    {:noreply, assign(socket, :current_state, :skipping)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="terminal-container"
      class="fixed inset-0 bg-[#080706] overflow-hidden"
      phx-window-keydown="keydown"
    >
      <!-- Subtle vignette -->
      <div class="pointer-events-none fixed inset-0 bg-radial-dark"></div>

      <!-- Emergence area - center of screen -->
      <div class="absolute inset-0 flex items-center justify-center">
        <%= if @view_mode == :discover do %>
          <.emergence_view
            current={@current}
            state={@current_state}
            drift_seed={@drift_seed}
          />
        <% else %>
          <.bucket_view
            bucket={Enum.at(@buckets, @active_bucket)}
            index={@active_bucket}
          />
        <% end %>
      </div>

      <!-- Bucket indicators - bottom center -->
      <div class="absolute bottom-8 left-1/2 -translate-x-1/2 flex items-center gap-3">
        <%= for {bucket, index} <- Enum.with_index(@buckets) do %>
          <button
            phx-click="view_bucket"
            phx-value-index={index}
            class={[
              "w-8 h-8 rounded-full border transition-all duration-300 flex items-center justify-center text-xs font-mono",
              if(@active_bucket == index,
                do: "border-[#8b9a7d] bg-[#8b9a7d]/20 text-[#8b9a7d]",
                else: "border-[#2a2522] text-[#3a3530] hover:border-[#5a4f42] hover:text-[#5a4f42]"
              )
            ]}
            title={bucket.title}
          >
            <%= index + 1 %>
          </button>
        <% end %>

        <!-- Empty bucket slots (subtle) -->
        <%= for i <- length(@buckets)..5 do %>
          <div class="w-8 h-8 rounded-full border border-[#1a1714] border-dashed flex items-center justify-center text-[#1a1714] text-xs font-mono">
            <%= i + 1 %>
          </div>
        <% end %>
      </div>

      <!-- Queue indicator - top right, very subtle -->
      <div class="absolute top-6 right-6 text-[#2a2522] text-xs font-mono">
        <%= length(@queue) %> remaining
      </div>

      <!-- Help hint - bottom right -->
      <div class="absolute bottom-8 right-6">
        <button
          phx-click="keydown"
          phx-value-key="?"
          class="text-[#2a2522] hover:text-[#5a4f42] text-xs font-mono transition-colors"
        >
          <%= if @show_help, do: "hide", else: "?" %>
        </button>
      </div>

      <!-- Help overlay -->
      <%= if @show_help do %>
        <.help_overlay />
      <% end %>

      <!-- Auth - top left, minimal -->
      <div class="absolute top-6 left-6 flex items-center gap-4">
        <span class="text-[#2a2522] text-[10px] font-mono tracking-widest uppercase">Gridroom</span>
        <%= if @logged_in do %>
          <span class="text-[#3a3530] text-xs font-mono"><%= @user.username %></span>
        <% else %>
          <.link navigate={~p"/login"} class="text-[#3a3530] hover:text-[#5a4f42] text-xs font-mono">
            sign in
          </.link>
        <% end %>
      </div>
    </div>
    """
  end

  # The emerging discussion - single item floating in void
  defp emergence_view(assigns) do
    ~H"""
    <div class="relative w-full max-w-2xl px-8">
      <%= if @current do %>
        <div class={emergence_classes(@state)} style={drift_style(@drift_seed)}>
          <!-- Main title -->
          <h2 class={[
            "text-2xl md:text-3xl font-light tracking-wide text-center mb-4 transition-colors duration-500",
            if(@state == :visible, do: "text-[#c4b8a8]", else: "text-[#5a4f42]")
          ]}>
            <%= @current.title %>
          </h2>

          <!-- Description (if exists) -->
          <%= if @current.description && @current.description != "" do %>
            <p class={[
              "text-center text-sm md:text-base font-light transition-colors duration-500 max-w-md mx-auto",
              if(@state == :visible, do: "text-[#5a4f42]", else: "text-[#3a3530]")
            ]}>
              "<%= @current.description %>"
            </p>
          <% end %>

          <!-- Activity indicator - very subtle -->
          <div class="flex items-center justify-center gap-2 mt-6">
            <div class={["w-1.5 h-1.5 rounded-full", activity_dot(@current.activity.level)]}></div>
            <span class="text-[#3a3530] text-[10px] font-mono uppercase tracking-wider">
              <%= @current.activity.level %>
            </span>
          </div>

          <!-- Action hints - always present for layout, fade in when visible -->
          <div class={[
            "flex items-center justify-center gap-8 mt-12 text-[10px] font-mono uppercase tracking-wider transition-opacity duration-700",
            if(@state == :visible, do: "opacity-100", else: "opacity-0 pointer-events-none")
          ]}>
            <button
              phx-click="bucket_current"
              class="text-[#3a3530] hover:text-[#8b9a7d] transition-colors flex items-center gap-2"
            >
              <span class="text-[#5a4f42]">space</span> keep
            </button>
            <button
              phx-click="dismiss_current"
              class="text-[#3a3530] hover:text-[#5a4f42] transition-colors flex items-center gap-2"
            >
              <span class="text-[#5a4f42]">x</span> skip
            </button>
          </div>
        </div>
      <% else %>
        <!-- Void state - waiting -->
        <div class="text-center">
          <div class="w-2 h-2 rounded-full bg-[#2a2522] mx-auto void-indicator"></div>
        </div>
      <% end %>
    </div>
    """
  end

  # Viewing a bucketed discussion
  defp bucket_view(assigns) do
    ~H"""
    <div class="relative w-full max-w-xl px-8 animate-fade-in">
      <%= if @bucket do %>
        <div class="text-center">
          <!-- Bucket number -->
          <div class="text-[#5a4f42] text-xs font-mono mb-6">
            bucket <%= @index + 1 %>
          </div>

          <!-- Title -->
          <h2 class="text-2xl md:text-3xl font-light tracking-wide text-[#e8e0d5] mb-4">
            <%= @bucket.title %>
          </h2>

          <!-- Description -->
          <%= if @bucket.description && @bucket.description != "" do %>
            <p class="text-[#8a7d6d] text-sm md:text-base font-light max-w-md mx-auto mb-8">
              "<%= @bucket.description %>"
            </p>
          <% end %>

          <!-- Activity -->
          <div class="flex items-center justify-center gap-2 mb-8">
            <div class={["w-1.5 h-1.5 rounded-full", activity_dot(@bucket.activity.level)]}></div>
            <span class="text-[#3a3530] text-[10px] font-mono uppercase tracking-wider">
              <%= @bucket.activity.level %>
              <%= if @bucket.activity.count > 0 do %>
                · <%= @bucket.activity.count %> messages
              <% end %>
            </span>
          </div>

          <!-- Actions -->
          <div class="flex items-center justify-center gap-6">
            <button
              phx-click="enter_discussion"
              phx-value-id={@bucket.id}
              class="px-6 py-3 border border-[#8b9a7d] text-[#8b9a7d] text-sm font-mono uppercase tracking-wider hover:bg-[#8b9a7d]/10 transition-colors"
            >
              Enter
            </button>
            <button
              phx-click="remove_bucket"
              phx-value-index={@index}
              class="px-6 py-3 border border-[#2a2522] text-[#5a4f42] text-sm font-mono uppercase tracking-wider hover:border-[#d4756a] hover:text-[#d4756a] transition-colors"
            >
              Remove
            </button>
          </div>

          <!-- Return hint -->
          <p class="text-[#3a3530] text-[10px] font-mono mt-8">
            <span class="text-[#5a4f42]">esc</span> return to discovery
          </p>
        </div>
      <% end %>
    </div>
    """
  end

  # Help overlay
  defp help_overlay(assigns) do
    ~H"""
    <div class="absolute inset-0 bg-[#080706]/90 flex items-center justify-center z-50 animate-fade-in">
      <div class="text-center max-w-sm">
        <h3 class="text-[#8a7d6d] text-sm font-mono uppercase tracking-wider mb-8">Controls</h3>

        <div class="space-y-4 text-left">
          <div class="flex items-center gap-4">
            <span class="w-20 text-right text-[#5a4f42] text-xs font-mono">space</span>
            <span class="text-[#8a7d6d] text-sm">keep discussion</span>
          </div>
          <div class="flex items-center gap-4">
            <span class="w-20 text-right text-[#5a4f42] text-xs font-mono">x</span>
            <span class="text-[#8a7d6d] text-sm">skip to next</span>
          </div>
          <div class="flex items-center gap-4">
            <span class="w-20 text-right text-[#5a4f42] text-xs font-mono">1-6</span>
            <span class="text-[#8a7d6d] text-sm">view saved discussion</span>
          </div>
          <div class="flex items-center gap-4">
            <span class="w-20 text-right text-[#5a4f42] text-xs font-mono">esc</span>
            <span class="text-[#8a7d6d] text-sm">return to discovery</span>
          </div>
        </div>

        <p class="text-[#3a3530] text-[10px] font-mono mt-8">
          press any key to close
        </p>
      </div>
    </div>
    """
  end

  # Helper functions - using Lumon CSS animation classes
  defp emergence_classes(:void), do: "opacity-0"
  defp emergence_classes(:emerging), do: "terminal-emerging"
  defp emergence_classes(:visible), do: "terminal-visible"
  defp emergence_classes(:keeping), do: "terminal-keeping"
  defp emergence_classes(:skipping), do: "terminal-skipping"

  defp drift_style(seed) do
    # Subtle floating animation offset based on seed
    x_offset = rem(seed, 20) - 10
    "transform: translateX(#{x_offset}px);"
  end

  defp activity_dot(:buzzing), do: "bg-[#c9a962] animate-pulse"
  defp activity_dot(:active), do: "bg-[#8b9a7d]"
  defp activity_dot(:quiet), do: "bg-[#5a4f42]"
  defp activity_dot(:dormant), do: "bg-[#3a3530]"
end
