defmodule GridroomWeb.TerminalLive do
  @moduledoc """
  Lumon-inspired terminal interface for discovering discussions.

  Discussions emerge one at a time from the void. You curate through
  rejection - bucket what interests you, dismiss what doesn't.
  """

  use GridroomWeb, :live_view

  alias Gridroom.{Grid, Accounts}
  alias GridroomWeb.Presence

  @emerge_delay_ms 1200   # Void before title appears - let emptiness breathe
  @title_materialize_ms 2500  # Slow materialization of title
  @post_title_pause 1500  # Silence after title settles
  @description_surface_ms 2000  # Description surfaces slowly
  @dismiss_delay_ms 600   # Things have weight when leaving

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

    # Load user's saved buckets from DB, filtering out any that are "gone"
    buckets = load_user_buckets(user)
    bucket_ids = Enum.map(buckets, & &1.id) |> MapSet.new()

    # Load dismissed node IDs for this user
    dismissed_ids = Accounts.list_dismissed_node_ids(user) |> MapSet.new()

    # Combine: exclude both dismissed AND already-bucketed nodes
    excluded_ids = MapSet.union(dismissed_ids, bucket_ids)

    # Load and shuffle nodes for discovery order, excluding dismissed/bucketed ones
    nodes =
      Grid.list_nodes_with_activity()
      |> Enum.reject(fn node -> MapSet.member?(excluded_ids, node.id) end)
      |> Enum.shuffle()

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:logged_in, user && user.username != nil)
     |> assign(:queue, nodes)  # Remaining nodes to show
     |> assign(:current, nil)  # Currently visible discussion
     |> assign(:current_state, :void)  # :void, :emerging, :present, :keeping, :skipping
     |> assign(:buckets, buckets)  # Saved discussions from DB (max 6)
     |> assign(:new_bucket_index, nil)  # Track newly added bucket for animation
     |> assign(:active_bucket, nil)  # Currently viewing bucket index
     |> assign(:view_mode, :discover)  # :discover or :viewing
     |> assign(:drift_seed, :rand.uniform(1000))  # For drift variation
     |> assign(:page_title, "Innie Chat")
     |> assign(:show_help, false)}
  end

  # Load buckets from user's saved IDs, filtering out gone nodes
  defp load_user_buckets(user) do
    user.bucket_ids
    |> Enum.map(&Grid.get_node_with_activity/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(fn node -> node.decay == :gone end)
  end

  # Emergence flow - slow, deliberate presence
  @impl true
  def handle_info(:emerge_next, socket) do
    queue = socket.assigns.queue

    if socket.assigns.view_mode == :discover and Enum.any?(queue) do
      [next | rest] = queue
      # Begin materialization - CSS handles the slow fade
      # Schedule when it becomes interactive
      total_time = @title_materialize_ms + @post_title_pause + @description_surface_ms
      Process.send_after(self(), :become_present, total_time)

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

  # Fully materialized - now interactive
  @impl true
  def handle_info(:become_present, socket) do
    if socket.assigns.current_state == :emerging do
      {:noreply, assign(socket, :current_state, :present)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(:dismiss_complete, socket) do
    # After dismiss animation, trigger next emergence
    Process.send_after(self(), :emerge_next, @dismiss_delay_ms)
    {:noreply, socket |> assign(:current, nil) |> assign(:current_state, :void)}
  end

  @impl true
  def handle_info({:node_created, node}, socket) do
    user = socket.assigns.user
    bucket_ids = Enum.map(socket.assigns.buckets, & &1.id)

    # Only add if not dismissed and not already bucketed
    if Accounts.node_dismissed?(user, node.id) or node.id in bucket_ids do
      {:noreply, socket}
    else
      # Add new nodes to front of queue
      {:noreply, assign(socket, :queue, [node | socket.assigns.queue])}
    end
  end

  @impl true
  def handle_info({:resonance_changed, _}, socket), do: {:noreply, socket}

  @impl true
  def handle_info(:clear_new_bucket, socket) do
    {:noreply, assign(socket, :new_bucket_index, nil)}
  end

  # Keybinds - always responsive, no waiting
  @impl true
  def handle_event("keydown", %{"key" => key}, socket) do
    has_current? = socket.assigns.current != nil
    in_discover? = socket.assigns.view_mode == :discover
    can_act? = socket.assigns.current_state in [:emerging, :present]

    cond do
      # Bucket current discussion (Space or Enter) - responsive immediately
      key in [" ", "Enter"] and has_current? and in_discover? and can_act? ->
        bucket_current(socket)

      # Dismiss current discussion (X, Backspace) - responsive immediately
      key in ["x", "X", "Backspace"] and has_current? and in_discover? and can_act? ->
        dismiss_current(socket)

      # Escape - return to discover from viewing, or dismiss in discover
      key == "Escape" ->
        if socket.assigns.view_mode == :viewing do
          {:noreply, socket |> assign(:view_mode, :discover) |> assign(:active_bucket, nil)}
        else
          if has_current? and can_act? do
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

      # C - clear all buckets
      key in ["c", "C"] and length(socket.assigns.buckets) > 0 ->
        clear_all_buckets(socket)

      # N - create new (if logged in)
      key in ["n", "N"] and socket.assigns.logged_in ->
        {:noreply, push_navigate(socket, to: ~p"/grid")}  # Use grid for creation for now

      true ->
        {:noreply, socket}
    end
  end

  # Click to bucket - responsive immediately
  @impl true
  def handle_event("bucket_current", _params, socket) do
    can_act? = socket.assigns.current != nil and socket.assigns.current_state in [:emerging, :present]
    if can_act? do
      bucket_current(socket)
    else
      {:noreply, socket}
    end
  end

  # Click to dismiss - responsive immediately
  @impl true
  def handle_event("dismiss_current", _params, socket) do
    can_act? = socket.assigns.current != nil and socket.assigns.current_state in [:emerging, :present]
    if can_act? do
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
    user = socket.assigns.user

    # Update DB
    {:ok, updated_user} = Accounts.remove_from_buckets(user, index)

    # Reload buckets from updated user
    buckets = load_user_buckets(updated_user)

    socket = socket
      |> assign(:user, updated_user)
      |> assign(:buckets, buckets)

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
    user = socket.assigns.user

    case Accounts.add_to_buckets(user, current.id) do
      {:ok, updated_user} ->
        new_index = length(socket.assigns.buckets)
        new_buckets = socket.assigns.buckets ++ [current]

        # Longer delay for keep animation - savoring the moment
        Process.send_after(self(), :dismiss_complete, 800)
        # Clear new bucket animation after it completes
        Process.send_after(self(), :clear_new_bucket, 1000)

        {:noreply,
         socket
         |> assign(:user, updated_user)
         |> assign(:buckets, new_buckets)
         |> assign(:new_bucket_index, new_index)
         |> assign(:current_state, :keeping)}

      {:error, :buckets_full} ->
        {:noreply, socket}

      {:error, :already_bucketed} ->
        # Already in buckets - just dismiss and move on
        Process.send_after(self(), :dismiss_complete, @dismiss_delay_ms)
        {:noreply, assign(socket, :current_state, :skipping)}
    end
  end

  defp clear_all_buckets(socket) do
    user = socket.assigns.user
    {:ok, updated_user} = Accounts.clear_buckets(user)

    {:noreply,
     socket
     |> assign(:user, updated_user)
     |> assign(:buckets, [])
     |> assign(:active_bucket, nil)
     |> assign(:view_mode, :discover)}
  end

  defp dismiss_current(socket) do
    current = socket.assigns.current
    user = socket.assigns.user

    # Persist dismissal to database
    if current do
      Accounts.dismiss_node(user, current.id)
    end

    Process.send_after(self(), :dismiss_complete, @dismiss_delay_ms)
    {:noreply, assign(socket, :current_state, :skipping)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="terminal-container"
      class="fixed inset-0 lumon-terminal overflow-hidden"
      phx-window-keydown="keydown"
    >
      <!-- CRT atmosphere layers -->
      <div class="pointer-events-none fixed inset-0 lumon-vignette"></div>
      <div class="pointer-events-none fixed inset-0 lumon-scanlines"></div>
      <div class="pointer-events-none fixed inset-0 lumon-glow"></div>

      <!-- Emergence area - center of screen -->
      <div class="absolute inset-0 flex items-center justify-center">
        <%= if @view_mode == :discover do %>
          <.emergence_view
            current={@current}
            state={@current_state}
            drift_seed={@drift_seed}
            queue_empty={Enum.empty?(@queue)}
            has_buckets={length(@buckets) > 0}
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
              "w-8 h-8 rounded-full border flex items-center justify-center text-xs font-mono",
              if(@new_bucket_index == index,
                do: "bucket-new-glow",
                else: "transition-all duration-300"
              ),
              if(@active_bucket == index,
                do: "border-[#8b9a7d] bg-[#8b9a7d]/20 text-[#8b9a7d]",
                else: "border-[#8b9a7d]/60 text-[#8b9a7d]/80 hover:border-[#8b9a7d] hover:text-[#8b9a7d]"
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

      <!-- Auth - top left, Lumon style -->
      <div class="absolute top-6 left-6 flex items-center gap-6">
        <span class="text-[#4a4540] text-[10px] font-mono tracking-[0.3em] uppercase">Innie Chat</span>
        <%= if @logged_in do %>
          <span class="text-[#5a4f42] text-xs font-mono tracking-wider"><%= @user.username %></span>
          <.link navigate={~p"/logout"} method="delete" class="text-[#3a3530] hover:text-[#5a4f42] text-[10px] font-mono tracking-wider uppercase">
            clock out
          </.link>
        <% else %>
          <.link navigate={~p"/login"} class="text-[#3a3530] hover:text-[#5a4f42] text-[10px] font-mono tracking-wider uppercase">
            clock in
          </.link>
          <.link navigate={~p"/register"} class="text-[#3a3530] hover:text-[#5a4f42] text-[10px] font-mono tracking-wider uppercase">
            request access
          </.link>
        <% end %>
      </div>
    </div>
    """
  end

  # The emerging discussion - Severance terminal aesthetic
  defp emergence_view(assigns) do
    ~H"""
    <div class="relative w-full max-w-2xl px-8">
      <%= if @current do %>
        <div class={emergence_container_classes(@state)}>
          <!-- Title - terminal text, soft glow -->
          <h2 class={[
            "text-xl md:text-3xl font-mono font-normal tracking-wide text-center leading-relaxed",
            title_classes(@state)
          ]}>
            <%= @current.title %>
          </h2>

          <!-- Description - dimmer, secondary -->
          <%= if @current.description && @current.description != "" do %>
            <p class={[
              "text-center text-sm font-mono font-light leading-relaxed mt-10 max-w-lg mx-auto",
              description_classes(@state)
            ]}>
              <%= @current.description %>
            </p>
          <% end %>

          <!-- Action hints - always visible when there's content -->
          <div class={[
            "flex items-center justify-center gap-20 mt-16 transition-opacity duration-500",
            if(@state in [:emerging, :present], do: "opacity-30", else: "opacity-0")
          ]}>
            <button
              phx-click="bucket_current"
              class="text-[#4a4540] hover:text-[#7a7570] text-[10px] font-mono tracking-widest uppercase transition-colors duration-200"
            >
              space
            </button>
            <button
              phx-click="dismiss_current"
              class="text-[#4a4540] hover:text-[#7a7570] text-[10px] font-mono tracking-widest uppercase transition-colors duration-200"
            >
              x
            </button>
          </div>
        </div>
      <% else %>
        <!-- Void state - centered -->
        <div class="w-full flex items-center justify-center">
          <%= if @queue_empty do %>
            <!-- All topics reviewed - Lumon completion message -->
            <div class="text-center space-y-8 animate-fade-in">
              <p class="text-[#4a4540] text-xs font-mono tracking-[0.3em] uppercase">
                all topics reviewed
              </p>
              <div class="w-8 h-px bg-[#2a2522] mx-auto"></div>
              <%= if @has_buckets do %>
                <p class="text-[#3a3530] text-[10px] font-mono tracking-widest">
                  your selections await
                </p>
              <% else %>
                <p class="text-[#3a3530] text-[10px] font-mono tracking-widest">
                  return when ready
                </p>
              <% end %>
            </div>
          <% else %>
            <!-- Waiting for next emergence -->
            <div class="w-1.5 h-1.5 rounded-full bg-[#2a2522] void-indicator"></div>
          <% end %>
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
    <div class="fixed inset-0 bg-[#080706]/95 flex items-center justify-center z-50 animate-fade-in">
      <div class="text-center max-w-sm mx-auto px-8">
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
            <span class="text-[#8a7d6d] text-sm">enter saved discussion</span>
          </div>
          <div class="flex items-center gap-4">
            <span class="w-20 text-right text-[#5a4f42] text-xs font-mono">c</span>
            <span class="text-[#8a7d6d] text-sm">clear all saved</span>
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

  # Helper functions - Severance terminal styling

  # Container classes - handles keep/skip animations
  defp emergence_container_classes(:keeping), do: "severance-keeping"
  defp emergence_container_classes(:skipping), do: "severance-skipping"
  defp emergence_container_classes(_), do: ""

  # Title - warm terminal phosphor glow
  defp title_classes(:emerging), do: "severance-title-emerging text-[#e0d8cc]"
  defp title_classes(:present), do: "severance-title-present text-[#e8e0d4]"
  defp title_classes(:keeping), do: "severance-title-present text-[#e8e0d4]"
  defp title_classes(:skipping), do: "text-[#e8e0d4]"
  defp title_classes(_), do: "opacity-0"

  # Description - softer, secondary
  defp description_classes(:emerging), do: "severance-description-emerging text-[#9a9488]"
  defp description_classes(:present), do: "severance-description-present text-[#a8a298]"
  defp description_classes(:keeping), do: "text-[#a8a298]"
  defp description_classes(:skipping), do: "text-[#a8a298]"
  defp description_classes(_), do: "opacity-0"

  # Activity dots for bucket view
  defp activity_dot(:buzzing), do: "bg-[#c9a962] animate-pulse"
  defp activity_dot(:active), do: "bg-[#8b9a7d]"
  defp activity_dot(:quiet), do: "bg-[#5a4f42]"
  defp activity_dot(:dormant), do: "bg-[#3a3530]"

  # Activity indicator - subtle terminal presence
  defp activity_dot_visible(:buzzing), do: "w-1.5 h-1.5 rounded-full bg-[#c9a962] shadow-[0_0_8px_rgba(201,169,98,0.5)] animate-pulse"
  defp activity_dot_visible(:active), do: "w-1.5 h-1.5 rounded-full bg-[#8b9a7d] shadow-[0_0_6px_rgba(139,154,125,0.4)]"
  defp activity_dot_visible(:quiet), do: "w-1 h-1 rounded-full bg-[#6a6258]"
  defp activity_dot_visible(:dormant), do: "w-1 h-1 rounded-full bg-[#4a4540]"
end
