defmodule GridroomWeb.GridLive do
  use GridroomWeb, :live_view

  alias Gridroom.{Grid, Accounts, Resonance}
  alias GridroomWeb.Presence

  # Node entry constants
  @entry_threshold 40
  @dwell_time_ms 1500
  @dwell_tick_ms 50

  @impl true
  def mount(params, session, socket) do
    # Check for logged-in user first, then fall back to anonymous session
    user =
      case session["user_id"] do
        nil ->
          # Anonymous user - create from session token
          session_id = session["_csrf_token"] || Ecto.UUID.generate()
          {:ok, user} = Accounts.get_or_create_user(session_id)
          user

        user_id ->
          # Logged-in user
          Accounts.get_user(user_id)
      end

    # Subscribe to presence, node updates, and personal resonance changes
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Gridroom.PubSub, "grid:presence")
      Phoenix.PubSub.subscribe(Gridroom.PubSub, "grid:nodes")
      Phoenix.PubSub.subscribe(Gridroom.PubSub, "user:#{user.id}:resonance")
      Presence.track_user(self(), user)
    end

    # Load initial nodes with activity
    nodes = Grid.list_nodes_with_activity()

    # Check if returning from a node - position player just outside it
    {player_pos, can_enter} = case params do
      %{"from" => node_id} ->
        case Grid.get_node(node_id) do
          nil -> {%{x: -50, y: -50}, false}
          node ->
            # Position player 60 units away from node center (outside entry threshold)
            offset_x = 60
            offset_y = 0
            {%{x: node.position_x + offset_x, y: node.position_y + offset_y}, false}
        end
      _ ->
        {%{x: -50, y: -50}, false}
    end

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:logged_in, user && user.username != nil)
     |> assign(:nodes, nodes)
     |> assign(:player, player_pos)
     |> assign(:viewport, %{x: player_pos.x, y: player_pos.y, zoom: 1.0})
     |> assign(:camera_follow, true)
     |> assign(:users, %{})
     |> assign(:entering_node, nil)
     |> assign(:can_enter_node, can_enter)
     |> assign(:dwelling_node, nil)
     |> assign(:dwell_progress, 0.0)
     |> assign(:page_title, "Gridroom")
     |> assign(:show_create_node, false)
     |> assign(:create_node_form, to_form(%{"title" => "", "description" => "", "node_type" => "discussion"}))
     |> assign(:selected_node, nil)
     |> assign(:resonance_toasts, [])}
  end

  @impl true
  def handle_event("pan", %{"dx" => dx, "dy" => dy}, socket) do
    viewport = socket.assigns.viewport
    new_viewport = %{viewport | x: viewport.x + dx, y: viewport.y + dy}
    # Panning disables camera follow until re-centered
    {:noreply,
     socket
     |> assign(:viewport, new_viewport)
     |> assign(:camera_follow, false)}
  end

  @impl true
  def handle_event("zoom", %{"delta" => delta, "x" => _x, "y" => _y}, socket) do
    viewport = socket.assigns.viewport
    zoom_factor = if delta > 0, do: 0.9, else: 1.1
    # Limit zoom out to 0.2 (20%) to preserve sense of discovery
    new_zoom = max(0.2, min(4.0, viewport.zoom * zoom_factor))
    {:noreply, assign(socket, :viewport, %{viewport | zoom: new_zoom})}
  end

  # Neighborhood radius - how far to show when zooming out
  @neighborhood_radius 600

  @impl true
  def handle_event("zoom_to_fit", _params, socket) do
    # Zoom out to show nearby nodes (neighborhood view, not everything)
    player = socket.assigns.player
    nodes = socket.assigns.nodes

    # Find nodes within the neighborhood radius
    nearby_nodes = Enum.filter(nodes, fn node ->
      distance_to_node(player, node) <= @neighborhood_radius
    end)

    if Enum.empty?(nearby_nodes) do
      # No nearby nodes - just zoom out a bit to show more area
      viewport = socket.assigns.viewport
      new_zoom = max(0.3, viewport.zoom * 0.5)
      {:noreply, assign(socket, :viewport, %{viewport | zoom: new_zoom})}
    else
      # Calculate bounding box of nearby nodes + player position
      xs = [player.x | Enum.map(nearby_nodes, & &1.position_x)]
      ys = [player.y | Enum.map(nearby_nodes, & &1.position_y)]
      min_x = Enum.min(xs) - 80
      max_x = Enum.max(xs) + 80
      min_y = Enum.min(ys) - 80
      max_y = Enum.max(ys) + 80

      # Calculate required zoom to fit nearby nodes
      width_needed = max_x - min_x
      height_needed = max_y - min_y
      zoom_x = 1000 / width_needed
      zoom_y = 600 / height_needed
      # Limit zoom out to 0.25 minimum to maintain some mystery
      new_zoom = max(0.25, min(1.0, min(zoom_x, zoom_y) * 0.85))

      # Center on the neighborhood
      center_x = (min_x + max_x) / 2
      center_y = (min_y + max_y) / 2

      {:noreply,
       socket
       |> assign(:viewport, %{x: center_x, y: center_y, zoom: new_zoom})
       |> assign(:camera_follow, false)}
    end
  end

  @impl true
  def handle_event("move", %{"dx" => dx, "dy" => dy}, socket) do
    player = socket.assigns.player
    viewport = socket.assigns.viewport
    speed = 8 / viewport.zoom
    new_player = %{x: player.x + dx * speed, y: player.y + dy * speed}

    # Update presence with new position
    user = socket.assigns.user
    Presence.update_position(self(), user, new_player.x, new_player.y)

    # Enable node entry after first movement (grace period)
    socket = if socket.assigns.can_enter_node do
      check_node_proximity(socket, new_player)
    else
      assign(socket, :can_enter_node, true)
    end

    # Camera follow - viewport tracks player position
    socket = if socket.assigns.camera_follow do
      assign(socket, :viewport, %{viewport | x: new_player.x, y: new_player.y})
    else
      socket
    end

    {:noreply, assign(socket, :player, new_player)}
  end

  @impl true
  def handle_event("update_position", %{"x" => x, "y" => y}, socket) do
    user = socket.assigns.user
    Presence.update_position(self(), user, x, y)
    {:noreply, socket}
  end

  @impl true
  def handle_event("select_node", %{"id" => node_id}, socket) do
    node = Enum.find(socket.assigns.nodes, &(&1.id == node_id))
    {:noreply, assign(socket, :selected_node, node)}
  end

  @impl true
  def handle_event("deselect_node", _params, socket) do
    {:noreply, assign(socket, :selected_node, nil)}
  end

  @impl true
  def handle_event("enter_node", %{"id" => node_id}, socket) do
    # Trigger the entry animation via JS
    {:noreply,
     socket
     |> assign(:entering_node, node_id)
     |> assign(:selected_node, nil)
     |> push_event("confirm_enter_node", %{node_id: node_id})}
  end

  @impl true
  def handle_event("enter_selected_node", _params, socket) do
    case socket.assigns.selected_node do
      nil -> {:noreply, socket}
      node ->
        {:noreply,
         socket
         |> assign(:entering_node, node.id)
         |> assign(:selected_node, nil)
         |> push_event("confirm_enter_node", %{node_id: node.id})}
    end
  end

  @impl true
  def handle_event("navigate_to_node", %{"id" => node_id}, socket) do
    {:noreply, push_navigate(socket, to: "/node/#{node_id}")}
  end

  @impl true
  def handle_event("enable_camera_follow", _params, socket) do
    {:noreply, assign(socket, :camera_follow, true)}
  end

  @impl true
  def handle_event("open_create_node", _params, socket) do
    if socket.assigns.logged_in do
      {:noreply, assign(socket, :show_create_node, true)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("close_create_node", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_create_node, false)
     |> assign(:create_node_form, to_form(%{"title" => "", "description" => "", "node_type" => "discussion"}))}
  end

  @impl true
  def handle_event("create_node", %{"title" => title, "description" => description, "node_type" => node_type}, socket) do
    player = socket.assigns.player
    user = socket.assigns.user

    attrs = %{
      title: String.trim(title),
      description: String.trim(description),
      position_x: player.x,
      position_y: player.y,
      node_type: node_type,
      created_by_id: user.id
    }

    case Grid.create_node(attrs) do
      {:ok, node} ->
        {:noreply,
         socket
         |> assign(:show_create_node, false)
         |> assign(:create_node_form, to_form(%{"title" => "", "description" => "", "node_type" => "discussion"}))
         |> push_navigate(to: "/node/#{node.id}")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Could not create node: #{error_message(changeset)}")}
    end
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
    users = Presence.handle_diff(socket.assigns.users, diff)
    {:noreply, assign(socket, :users, users)}
  end

  @impl true
  def handle_info({:node_created, node}, socket) do
    nodes = socket.assigns.nodes ++ [node]
    {:noreply, assign(socket, :nodes, nodes)}
  end

  @impl true
  def handle_info({:resonance_changed, %{user: updated_user, amount: amount, reason: reason}}, socket) do
    # Update user data and show toast
    toast = %{
      id: System.unique_integer([:positive]),
      amount: amount,
      reason: reason,
      timestamp: System.system_time(:second)
    }

    # Schedule toast removal after 4 seconds
    Process.send_after(self(), {:remove_toast, toast.id}, 4000)

    {:noreply,
     socket
     |> assign(:user, updated_user)
     |> assign(:resonance_toasts, [toast | socket.assigns.resonance_toasts])}
  end

  @impl true
  def handle_info({:remove_toast, toast_id}, socket) do
    toasts = Enum.reject(socket.assigns.resonance_toasts, &(&1.id == toast_id))
    {:noreply, assign(socket, :resonance_toasts, toasts)}
  end

  @impl true
  def handle_info({:dwell_tick, node_id}, socket) do
    dwelling = socket.assigns.dwelling_node
    entering = socket.assigns.entering_node

    cond do
      # Already entering or no longer dwelling on this node
      entering || dwelling != node_id ->
        {:noreply, socket}

      # Still dwelling - increment progress
      true ->
        current = socket.assigns.dwell_progress
        increment = @dwell_tick_ms / @dwell_time_ms * 100
        new_progress = current + increment

        if new_progress >= 100 do
          # Dwell complete - trigger entry
          {:noreply,
           socket
           |> assign(:entering_node, node_id)
           |> assign(:dwelling_node, nil)
           |> assign(:dwell_progress, 100.0)
           |> push_event("confirm_enter_node", %{node_id: node_id})}
        else
          # Continue dwelling
          Process.send_after(self(), {:dwell_tick, node_id}, @dwell_tick_ms)
          {:noreply, assign(socket, :dwell_progress, new_progress)}
        end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="grid-container"
      class={"fixed inset-0 overflow-hidden select-none #{if @entering_node, do: "entering-node", else: ""}"}
      phx-hook="GridCanvas"
      data-viewport-x={@viewport.x}
      data-viewport-y={@viewport.y}
      data-viewport-zoom={@viewport.zoom}
      data-player-x={@player.x}
      data-player-y={@player.y}
      data-entering-node={@entering_node}
    >
      <svg
        id="grid-svg"
        class="w-full h-full"
        viewBox={viewbox(@viewport)}
        preserveAspectRatio="xMidYMid slice"
      >
        <defs>
          <!-- Sophisticated grid pattern -->
          <pattern id="grid-major" width="100" height="100" patternUnits="userSpaceOnUse">
            <path d="M 100 0 L 0 0 0 100" fill="none" stroke="rgba(139, 115, 85, 0.06)" stroke-width="0.5"/>
          </pattern>
          <pattern id="grid-minor" width="20" height="20" patternUnits="userSpaceOnUse">
            <path d="M 20 0 L 0 0 0 20" fill="none" stroke="rgba(139, 115, 85, 0.02)" stroke-width="0.3"/>
          </pattern>

          <!-- Warm ambient glow -->
          <radialGradient id="ambient-glow" cx="50%" cy="50%" r="50%">
            <stop offset="0%" stop-color="rgba(219, 167, 111, 0.08)" />
            <stop offset="100%" stop-color="transparent" />
          </radialGradient>

          <!-- Node glow filter - soft warm -->
          <filter id="node-glow" x="-100%" y="-100%" width="300%" height="300%">
            <feGaussianBlur stdDeviation="4" result="blur1"/>
            <feGaussianBlur stdDeviation="8" result="blur2"/>
            <feMerge>
              <feMergeNode in="blur2"/>
              <feMergeNode in="blur1"/>
              <feMergeNode in="SourceGraphic"/>
            </feMerge>
          </filter>

          <!-- User glow filter -->
          <filter id="user-glow" x="-100%" y="-100%" width="300%" height="300%">
            <feGaussianBlur stdDeviation="3" result="blur"/>
            <feMerge>
              <feMergeNode in="blur"/>
              <feMergeNode in="SourceGraphic"/>
            </feMerge>
          </filter>

          <!-- Self glow - brighter -->
          <filter id="self-glow" x="-100%" y="-100%" width="300%" height="300%">
            <feGaussianBlur stdDeviation="2" result="blur1"/>
            <feGaussianBlur stdDeviation="6" result="blur2"/>
            <feGaussianBlur stdDeviation="12" result="blur3"/>
            <feMerge>
              <feMergeNode in="blur3"/>
              <feMergeNode in="blur2"/>
              <feMergeNode in="blur1"/>
              <feMergeNode in="SourceGraphic"/>
            </feMerge>
          </filter>

          <!-- Connection line gradient -->
          <linearGradient id="connection-fade" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stop-color="rgba(139, 115, 85, 0.3)" />
            <stop offset="50%" stop-color="rgba(139, 115, 85, 0.1)" />
            <stop offset="100%" stop-color="rgba(139, 115, 85, 0.3)" />
          </linearGradient>

        </defs>

        <!-- Background layers -->
        <rect width="10000" height="10000" x="-5000" y="-5000" fill="#0d0b0a" />
        <rect width="10000" height="10000" x="-5000" y="-5000" fill="url(#grid-minor)" />
        <rect width="10000" height="10000" x="-5000" y="-5000" fill="url(#grid-major)" />

        <!-- Grid intersection glow points -->
        <g class="grid-intersections">
          <%= for x <- -5..5, y <- -4..4 do %>
            <circle
              cx={x * 100}
              cy={y * 100}
              r="1.5"
              fill="#8b7355"
              class="animate-grid-pulse"
              style={"animation-delay: #{:erlang.phash2({x, y}, 10) * -0.6}s;"}
            />
          <% end %>
        </g>

        <!-- Ambient dust motes - scattered particles -->
        <g class="dust-motes">
          <%= for i <- 1..30 do %>
            <% {dx, dy} = dust_position(i) %>
            <circle
              cx={dx}
              cy={dy}
              r={0.8 + rem(i, 3) * 0.4}
              fill="#a89880"
              class="animate-dust"
              style={"animation-delay: #{i * -0.5}s;"}
            />
          <% end %>
        </g>

        <!-- Twinkling star specs -->
        <g class="star-specs">
          <%= for i <- 1..20 do %>
            <% {sx, sy} = star_position(i) %>
            <circle
              cx={sx}
              cy={sy}
              r={0.5 + rem(i, 2) * 0.3}
              fill="#d4c8b8"
              class="animate-twinkle"
              style={"animation-delay: #{i * -0.3}s;"}
            />
          <% end %>
        </g>

        <!-- Player light source - illuminates nearby area -->
        <ellipse cx={@player.x} cy={@player.y} rx="280" ry="220" fill="url(#ambient-glow)" class="animate-breathe" />

        <!-- Connection lines between nearby nodes -->
        <g class="connections" opacity="0.4">
          <%= for {n1, n2} <- node_connections(@nodes) do %>
            <line
              x1={n1.position_x}
              y1={n1.position_y}
              x2={n2.position_x}
              y2={n2.position_y}
              stroke="url(#connection-fade)"
              stroke-width="0.5"
              stroke-dasharray="4,8"
            />
          <% end %>
        </g>

        <!-- Topic nodes -->
        <%= for {node, index} <- Enum.with_index(@nodes) do %>
          <% activity = Map.get(node, :activity, %{level: :dormant, count: 0}) %>
          <% decay = Map.get(node, :decay, :fresh) %>
          <% proximity_brightness = node_proximity_brightness(@player, node) %>
          <% activity_brightness = activity_base_brightness(activity.level) %>
          <% decay_opacity = decay_opacity(decay) %>
          <% total_brightness = min(1.0, proximity_brightness + activity_brightness) * decay_opacity %>
          <g
            class={"node node-activity-#{activity.level} node-decay-#{decay}"}
            data-node-id={node.id}
            transform={"translate(#{node.position_x}, #{node.position_y})"}
            style={"animation-delay: #{rem(index, 5) * -0.8}s;"}
            opacity={total_brightness}
          >
            <!-- Soft backdrop glow -->
            <circle r="28" fill={node_type_color(node.node_type)} opacity="0.08" filter="url(#node-glow)" />

            <!-- Outer orbit ring - thin, elegant (dashed when fading) -->
            <circle
              r="30"
              fill="none"
              stroke={node_type_color(node.node_type)}
              stroke-width={if decay == :fading, do: "0.8", else: "0.5"}
              stroke-dasharray={if decay == :fading, do: "3,5", else: "2,8"}
              opacity={if decay == :fading, do: "0.5", else: "0.4"}
              class={if decay == :fading, do: "animate-pulse", else: "animate-breathe"}
            />

            <!-- Activity rings - warm pulses for active nodes -->
            <%= if activity.level == :buzzing do %>
              <circle r="40" fill="none" stroke={node_type_color(node.node_type)} stroke-width="0.6" opacity="0.25" class="animate-pulse-ring" />
              <circle r="35" fill="none" stroke={node_type_color(node.node_type)} stroke-width="0.5" opacity="0.2" class="animate-pulse-ring" style="animation-delay: -0.5s;" />
            <% end %>
            <%= if activity.level in [:active, :buzzing] do %>
              <circle r="32" fill="none" stroke={node_type_color(node.node_type)} stroke-width="0.4" opacity="0.3" class="animate-pulse-ring" style="animation-delay: -1s;" />
            <% end %>

            <!-- Node shape (click to select) -->
            <.node_shape node={node} color={node_type_color(node.node_type)} selected={@selected_node && @selected_node.id == node.id} />

            <!-- Inner glow for active nodes -->
            <%= if activity.level in [:active, :buzzing] do %>
              <circle
                r="12"
                fill={node_type_color(node.node_type)}
                opacity={if activity.level == :buzzing, do: "0.4", else: "0.25"}
                filter="url(#node-glow)"
                class="activity-core"
              />
            <% end %>

            <!-- Floating embers for buzzing nodes -->
            <%= if activity.level == :buzzing do %>
              <circle cx="18" cy="-14" r="1.2" fill={node_type_color(node.node_type)} opacity="0.5" class="animate-ember" style="animation-delay: 0s;" />
              <circle cx="-15" cy="12" r="1" fill={node_type_color(node.node_type)} opacity="0.4" class="animate-ember" style="animation-delay: -0.6s;" />
              <circle cx="10" cy="20" r="0.8" fill={node_type_color(node.node_type)} opacity="0.3" class="animate-ember" style="animation-delay: -1.2s;" />
            <% end %>

            <!-- Label - brightness responds to proximity -->
            <text
              y="42"
              text-anchor="middle"
              class="node-label pointer-events-none"
              fill={text_color_for_brightness(total_brightness)}
              style="font-size: 11px; font-family: 'Space Grotesk', sans-serif;"
            >
              <%= truncate_title(node.title, 24) %>
            </text>
            <!-- Creator username (if user-created) -->
            <%= if node.created_by && node.created_by.username do %>
              <text
                y="54"
                text-anchor="middle"
                class="node-creator pointer-events-none"
                fill={text_color_for_brightness(total_brightness * 0.6)}
                style="font-size: 9px; font-family: 'Space Grotesk', sans-serif; font-style: italic;"
              >
                by <%= node.created_by.username %>
              </text>
            <% end %>
            <!-- Decay state indicator (only for quiet/fading) -->
            <%= if decay in [:quiet, :fading] do %>
              <text
                y={if node.created_by && node.created_by.username, do: "66", else: "54"}
                text-anchor="middle"
                class="node-decay-label pointer-events-none"
                fill={decay_label_color(decay)}
                style="font-size: 8px; font-family: 'Space Grotesk', sans-serif; letter-spacing: 0.05em;"
              >
                <%= decay_time_text(node.last_activity_at, decay) %>
              </text>
            <% end %>
          </g>
        <% end %>

        <!-- Other users -->
        <%= for {_id, user_presence} <- @users do %>
          <%= if user_presence.user_id != @user.id do %>
            <g
              class="user-glyph animate-drift"
              transform={"translate(#{user_presence.x || 0}, #{user_presence.y || 0})"}
              filter="url(#user-glow)"
            >
              <.user_glyph shape={user_presence.glyph_shape} color={user_presence.glyph_color} />
            </g>
          <% end %>
        <% end %>

        <!-- Current user (you) - at player position -->
        <% resonance_level = Resonance.resonance_level(@user) %>
        <g
          id="current-user"
          class={"user-glyph-self resonance-#{resonance_level}"}
          transform={"translate(#{@player.x}, #{@player.y})"}
          filter={player_glyph_filter(resonance_level)}
          opacity={player_glyph_opacity(resonance_level)}
        >
          <.user_glyph shape={@user.glyph_shape} color={player_glyph_color(@user.glyph_color, resonance_level)} pulse={resonance_level != :depleted} />
          <!-- Subtle pulse ring -->
          <circle r="16" fill="none" stroke={player_glyph_color(@user.glyph_color, resonance_level)} stroke-width="0.5" opacity="0.3" class="animate-pulse-glow" />
          <!-- Movement indicator -->
          <circle r="20" fill="none" stroke={player_glyph_color(@user.glyph_color, resonance_level)} stroke-width="0.3" opacity="0.15" stroke-dasharray="2,4" class="animate-spin-slow" />
          <!-- Radiant/Elevated aura -->
          <%= if resonance_level in [:radiant, :elevated] do %>
            <circle
              r={if resonance_level == :radiant, do: "28", else: "24"}
              fill="none"
              stroke={if resonance_level == :radiant, do: "#c9a962", else: "#8b9a7d"}
              stroke-width={if resonance_level == :radiant, do: "2", else: "1"}
              opacity={if resonance_level == :radiant, do: "0.4", else: "0.25"}
              filter="url(#node-glow)"
              class="animate-breathe"
            />
          <% end %>
          <!-- Depleted warning indicator -->
          <%= if resonance_level == :depleted do %>
            <circle r="22" fill="none" stroke="#d4756a" stroke-width="1" opacity="0.5" stroke-dasharray="2,4" class="animate-pulse" />
          <% end %>

          <!-- Dwell progress ring -->
          <%= if @dwelling_node do %>
            <g class="dwell-indicator">
              <!-- Background ring -->
              <circle
                r="26"
                fill="none"
                stroke="rgba(219, 167, 111, 0.2)"
                stroke-width="3"
              />
              <!-- Progress ring - uses dashoffset for smooth progress -->
              <!-- Circumference = 2 * pi * 26 ≈ 163.4 -->
              <circle
                r="26"
                fill="none"
                stroke="#dba76f"
                stroke-width="3"
                stroke-dasharray="163.4"
                stroke-dashoffset={163.4 - (@dwell_progress / 100 * 163.4)}
                stroke-linecap="round"
                transform="rotate(-90 0 0)"
              />
              <!-- Glow effect -->
              <circle
                r="26"
                fill="none"
                stroke="#dba76f"
                stroke-width="6"
                opacity="0.3"
                stroke-dasharray="163.4"
                stroke-dashoffset={163.4 - (@dwell_progress / 100 * 163.4)}
                stroke-linecap="round"
                transform="rotate(-90 0 0)"
                filter="url(#node-glow)"
              />
            </g>
          <% end %>
        </g>

      </svg>

      <!-- UI Overlay - Bottom Left -->
      <div class="ui-overlay absolute bottom-6 left-6 flex items-center gap-4">
        <!-- Resonance meter -->
        <.resonance_meter user={@user} />
        <div class="w-px h-6 bg-[#2a2522]"></div>
        <div class="flex items-center gap-2">
          <div class="w-2 h-2 rounded-full bg-[#c9a962] animate-pulse"></div>
          <span class="ui-stat"><%= length(@nodes) %> nodes</span>
        </div>
        <div class="w-px h-3 bg-[#2a2522]"></div>
        <div class="flex items-center gap-2">
          <div class="w-2 h-2 rounded-full" style={"background-color: #{@user.glyph_color};"}></div>
          <span class="ui-stat"><%= map_size(@users) + 1 %> present</span>
        </div>
        <%= if @logged_in && !@show_create_node do %>
          <div class="w-px h-3 bg-[#2a2522]"></div>
          <button
            phx-click="open_create_node"
            class="text-[#dba76f] hover:text-[#e8b87a] text-xs transition-colors flex items-center gap-1"
          >
            <span class="text-lg leading-none">+</span> create node
          </button>
        <% end %>
      </div>

      <!-- Resonance change toasts -->
      <div class="fixed top-20 right-6 flex flex-col gap-2 z-50">
        <%= for toast <- @resonance_toasts do %>
          <.resonance_toast toast={toast} />
        <% end %>
      </div>

      <!-- UI Overlay - Top Right - Auth -->
      <div class="ui-overlay absolute top-6 right-6 flex items-center gap-4">
        <span class="ui-stat text-[#5a4f42]"><%= Float.round(@viewport.zoom * 100, 0) |> trunc %>%</span>
        <div class="w-px h-4 bg-[#2a2522]"></div>
        <%= if @logged_in do %>
          <div class="flex items-center gap-3">
            <div class="flex items-center gap-2">
              <svg width="16" height="16" viewBox="-10 -10 20 20">
                <.user_glyph shape={@user.glyph_shape} color={@user.glyph_color} />
              </svg>
              <span class="text-[#c4b8a8] text-sm"><%= @user.username %></span>
            </div>
            <.link href={~p"/logout"} method="delete" class="text-[#5a4f42] hover:text-[#c4b8a8] text-xs transition-colors">
              logout
            </.link>
          </div>
        <% else %>
          <div class="flex items-center gap-3">
            <span class="text-[#5a4f42] text-sm">guest</span>
            <.link navigate={~p"/login"} class="text-[#dba76f] hover:text-[#e8b87a] text-xs transition-colors">
              sign in
            </.link>
          </div>
        <% end %>
      </div>

      <!-- UI Overlay - Top Left - Title -->
      <div class="absolute top-6 left-6">
        <h1 class="text-[#5a4f42] text-sm tracking-[0.2em] uppercase font-light">Gridroom</h1>
      </div>

      <!-- Controls hint -->
      <div class="absolute bottom-6 right-6 ui-overlay text-[#3a3530] max-w-xs text-right">
        <div class="flex items-center gap-3 mb-2">
          <button
            phx-click="zoom_to_fit"
            class="text-[#5a4f42] hover:text-[#c9a962] text-[10px] uppercase tracking-wide transition-colors border border-[#2a2522] hover:border-[#c9a962]/40 px-2 py-1"
          >
            Nearby
          </button>
        </div>
        <p class="text-xs leading-relaxed opacity-60">
          <span class="text-[#5a4f42]">WASD</span> move ·
          <span class="text-[#5a4f42]">scroll</span> zoom ·
          <span class="text-[#5a4f42]">click</span> select
          <%= if @logged_in do %>
            · <span class="text-[#5a4f42]">N</span> new node
          <% end %>
          <%= if !@camera_follow do %>
            · <span class="text-[#c9a962]">detached</span>
          <% end %>
        </p>
      </div>

      <!-- Create Node Sidebar -->
      <%= if @show_create_node do %>
        <div class="absolute right-0 top-0 bottom-0 w-80 bg-[#0d0b0a]/95 border-l border-[#2a2522] flex flex-col">
          <!-- Header -->
          <div class="p-4 border-b border-[#2a2522] flex items-center justify-between">
            <h2 class="text-[#c4b8a8] text-sm tracking-wide uppercase">Create Node</h2>
            <button
              phx-click="close_create_node"
              class="text-[#5a4f42] hover:text-[#c4b8a8] text-xl leading-none transition-colors"
            >
              &times;
            </button>
          </div>

          <!-- Position indicator -->
          <div class="px-4 py-3 border-b border-[#2a2522]/50 bg-[#1a1714]/50">
            <p class="text-[#5a4f42] text-xs">
              Placing at position
              <span class="text-[#c9a962] font-mono">
                (<%= Float.round(@player.x, 0) |> trunc %>, <%= Float.round(@player.y, 0) |> trunc %>)
              </span>
            </p>
          </div>

          <!-- Form -->
          <form phx-submit="create_node" class="flex-1 flex flex-col p-4 gap-4">
            <div>
              <label class="block text-[#8a7d6d] text-xs uppercase tracking-wide mb-2">
                Title <span class="text-[#d4756a]">*</span>
              </label>
              <input
                type="text"
                name="title"
                placeholder="What's this node about?"
                required
                maxlength="50"
                class="w-full bg-[#1a1714] border border-[#2a2522] rounded px-3 py-2 text-[#e8e0d5] text-sm placeholder-[#5a4f42] focus:border-[#c9a962] focus:outline-none transition-colors"
              />
            </div>

            <div>
              <label class="block text-[#8a7d6d] text-xs uppercase tracking-wide mb-2">
                Description
              </label>
              <textarea
                name="description"
                placeholder="Optional details..."
                rows="3"
                maxlength="200"
                class="w-full bg-[#1a1714] border border-[#2a2522] rounded px-3 py-2 text-[#e8e0d5] text-sm placeholder-[#5a4f42] focus:border-[#c9a962] focus:outline-none transition-colors resize-none"
              ></textarea>
            </div>

            <div>
              <label class="block text-[#8a7d6d] text-xs uppercase tracking-wide mb-2">
                Type
              </label>
              <div class="grid grid-cols-2 gap-2">
                <%= for type <- ~w(discussion question debate quiet) do %>
                  <label class="flex items-center gap-2 p-2 rounded border border-[#2a2522] hover:border-[#5a4f42] cursor-pointer transition-colors has-[:checked]:border-[#c9a962] has-[:checked]:bg-[#c9a962]/10">
                    <input
                      type="radio"
                      name="node_type"
                      value={type}
                      checked={type == "discussion"}
                      class="sr-only"
                    />
                    <span class={"w-3 h-3 rounded-full #{node_type_class(type)}"}></span>
                    <span class="text-[#c4b8a8] text-xs capitalize"><%= type %></span>
                  </label>
                <% end %>
              </div>
            </div>

            <div class="flex-1"></div>

            <div class="flex gap-2">
              <button
                type="button"
                phx-click="close_create_node"
                class="flex-1 px-4 py-2 border border-[#2a2522] rounded text-[#8a7d6d] text-sm hover:border-[#5a4f42] hover:text-[#c4b8a8] transition-colors"
              >
                Cancel
              </button>
              <button
                type="submit"
                class="flex-1 px-4 py-2 bg-[#c9a962] rounded text-[#0d0b0a] text-sm font-medium hover:bg-[#dba76f] transition-colors"
              >
                Create
              </button>
            </div>
          </form>
        </div>
      <% end %>

      <!-- Selected Node Preview Panel -->
      <%= if @selected_node && !@show_create_node do %>
        <.node_preview_panel node={@selected_node} />
      <% end %>
    </div>
    """
  end

  # Node preview panel component
  defp node_preview_panel(assigns) do
    activity = Map.get(assigns.node, :activity, %{level: :dormant, count: 0})
    decay = Map.get(assigns.node, :decay, :fresh)
    assigns = assigns |> assign(:activity, activity) |> assign(:decay, decay)

    ~H"""
    <div class="absolute bottom-24 left-1/2 -translate-x-1/2 w-96 bg-[#0d0b0a]/95 border border-[#2a2522] backdrop-blur-sm animate-fade-in">
      <!-- Header with close button -->
      <div class="p-4 border-b border-[#2a2522] flex items-center justify-between">
        <div class="flex items-center gap-3">
          <div class={"w-3 h-3 rounded-full #{node_type_class(@node.node_type)}"}></div>
          <h3 class="text-[#e8e0d5] font-medium"><%= @node.title %></h3>
        </div>
        <button
          phx-click="deselect_node"
          class="text-[#5a4f42] hover:text-[#c4b8a8] text-xl leading-none transition-colors"
        >
          &times;
        </button>
      </div>

      <!-- Content -->
      <div class="p-4">
        <%= if @node.description do %>
          <p class="text-[#8a7d6d] text-sm mb-4 leading-relaxed"><%= @node.description %></p>
        <% end %>

        <!-- Activity and metadata -->
        <div class="flex items-center gap-4 mb-4 text-xs">
          <div class="flex items-center gap-2">
            <div class={"w-2 h-2 rounded-full #{activity_color(@activity.level)}"}></div>
            <span class="text-[#5a4f42] uppercase tracking-wide"><%= @activity.level %></span>
          </div>
          <%= if @activity.count > 0 do %>
            <span class="text-[#5a4f42]">·</span>
            <span class="text-[#8a7d6d]"><%= @activity.count %> messages this hour</span>
          <% end %>
          <%= if @decay in [:quiet, :fading] do %>
            <span class="text-[#5a4f42]">·</span>
            <span class={decay_preview_class(@decay)}><%= decay_time_text(@node.last_activity_at, @decay) %></span>
          <% end %>
        </div>

        <!-- Creator info -->
        <%= if @node.created_by && @node.created_by.username do %>
          <div class="flex items-center gap-2 mb-4">
            <svg width="14" height="14" viewBox="-10 -10 20 20">
              <.user_glyph shape={@node.created_by.glyph_shape || "circle"} color={@node.created_by.glyph_color || "#5a4f42"} />
            </svg>
            <span class="text-[#5a4f42] text-xs">Created by <span class="text-[#8a7d6d]"><%= @node.created_by.username %></span></span>
          </div>
        <% end %>

        <!-- Enter button -->
        <button
          phx-click="enter_selected_node"
          class="w-full px-4 py-3 bg-[#c9a962] rounded text-[#0d0b0a] text-sm font-medium hover:bg-[#dba76f] transition-colors flex items-center justify-center gap-2"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 9l3 3m0 0l-3 3m3-3H8m13 0a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          Enter Node
        </button>

        <p class="text-[#3a3530] text-[10px] text-center mt-3 tracking-wide">
          Press <span class="text-[#5a4f42]">Enter</span> or click to join the conversation
        </p>
      </div>
    </div>
    """
  end

  defp activity_color(:dormant), do: "bg-[#3a3530]"
  defp activity_color(:quiet), do: "bg-[#5a4f42]"
  defp activity_color(:active), do: "bg-[#8b9a7d]"
  defp activity_color(:buzzing), do: "bg-[#c9a962] animate-pulse"

  # Generate connections between nearby nodes
  defp node_connections(nodes) do
    for n1 <- nodes,
        n2 <- nodes,
        n1.id < n2.id,
        distance(n1, n2) < 200 do
      {n1, n2}
    end
  end

  defp distance(n1, n2) do
    :math.sqrt(:math.pow(n1.position_x - n2.position_x, 2) + :math.pow(n1.position_y - n2.position_y, 2))
  end

  defp distance_to_node(player, node) do
    :math.sqrt(:math.pow(player.x - node.position_x, 2) + :math.pow(player.y - node.position_y, 2))
  end

  defp check_node_proximity(socket, player) do
    nodes = socket.assigns.nodes
    entering = socket.assigns.entering_node
    dwelling = socket.assigns.dwelling_node

    # Don't check if already entering
    if entering do
      socket
    else
      nearby_node = Enum.find(nodes, fn node -> distance_to_node(player, node) < @entry_threshold end)

      cond do
        # Still on same node - continue dwelling
        nearby_node && dwelling && nearby_node.id == dwelling ->
          socket

        # Entered a new node's proximity - start dwelling
        nearby_node && (is_nil(dwelling) || nearby_node.id != dwelling) ->
          # Start dwell timer
          Process.send_after(self(), {:dwell_tick, nearby_node.id}, @dwell_tick_ms)
          socket
          |> assign(:dwelling_node, nearby_node.id)
          |> assign(:dwell_progress, 0.0)

        # Left all nodes - cancel dwelling
        is_nil(nearby_node) && dwelling ->
          socket
          |> assign(:dwelling_node, nil)
          |> assign(:dwell_progress, 0.0)

        # Not near any node and wasn't dwelling
        true ->
          socket
      end
    end
  end

  defp node_type_color("discussion"), do: "#c9a962"
  defp node_type_color("question"), do: "#7eb8da"
  defp node_type_color("debate"), do: "#d4756a"
  defp node_type_color("quiet"), do: "#8b9a7d"
  defp node_type_color(_), do: "#c9a962"

  defp node_type_class("discussion"), do: "bg-[#c9a962]"
  defp node_type_class("question"), do: "bg-[#7eb8da]"
  defp node_type_class("debate"), do: "bg-[#d4756a]"
  defp node_type_class("quiet"), do: "bg-[#8b9a7d]"
  defp node_type_class(_), do: "bg-[#c9a962]"

  # Pseudo-random positions for ambient particles (deterministic based on index)
  defp dust_position(i) do
    # Spread dust across visible area using simple hash
    x = rem(i * 137, 800) - 400
    y = rem(i * 97, 600) - 300
    {x, y}
  end

  defp star_position(i) do
    # Different spread pattern for stars
    x = rem(i * 173, 900) - 450
    y = rem(i * 113, 700) - 350
    {x, y}
  end

  # Player light source - nodes illuminated by proximity
  @player_light_radius 350
  @player_light_falloff 180  # Distance where light starts to fade

  defp node_proximity_brightness(player, node) do
    dist = distance_to_node(player, node)

    cond do
      dist < @player_light_falloff ->
        # Full illumination close to player
        1.0
      dist < @player_light_radius ->
        # Linear falloff from full to base
        falloff_range = @player_light_radius - @player_light_falloff
        falloff_progress = (dist - @player_light_falloff) / falloff_range
        1.0 - (0.4 * falloff_progress)  # 1.0 -> 0.6
      true ->
        # Outside light radius - visible but dimmer
        0.5
    end
  end

  # Activity-based self-illumination (adds to proximity brightness)
  defp activity_base_brightness(:dormant), do: 0.15
  defp activity_base_brightness(:quiet), do: 0.2
  defp activity_base_brightness(:active), do: 0.35
  defp activity_base_brightness(:buzzing), do: 0.5

  # Decay-based opacity multiplier
  defp decay_opacity(:fresh), do: 1.0
  defp decay_opacity(:quiet), do: 0.85
  defp decay_opacity(:fading), do: 0.5
  defp decay_opacity(_), do: 1.0

  # Decay label text (simple)
  defp decay_label_text(:quiet), do: "quiet"
  defp decay_label_text(:fading), do: "fading..."
  defp decay_label_text(_), do: ""

  # Decay time-based text
  defp decay_time_text(nil, decay), do: decay_label_text(decay)
  defp decay_time_text(last_activity_at, decay) do
    days_ago = DateTime.diff(DateTime.utc_now(), last_activity_at, :day)

    case decay do
      :quiet ->
        # Quiet = 1-7 days, fading starts at 7
        days_until_fading = max(0, 7 - days_ago)
        if days_until_fading > 0 do
          "#{days_ago}d ago"
        else
          "fading soon"
        end

      :fading ->
        # Fading = 7-14 days, gone at 14
        days_until_gone = max(0, 14 - days_ago)
        if days_until_gone > 0 do
          "gone in #{days_until_gone}d"
        else
          "disappearing..."
        end

      _ ->
        ""
    end
  end

  # Decay label color
  defp decay_label_color(:quiet), do: "#5a4f42"
  defp decay_label_color(:fading), do: "#d4756a"
  defp decay_label_color(_), do: "#3a3530"

  # Decay preview panel class
  defp decay_preview_class(:quiet), do: "text-[#5a4f42]"
  defp decay_preview_class(:fading), do: "text-[#d4756a]"
  defp decay_preview_class(_), do: "text-[#5a4f42]"

  # Player glyph resonance effects
  defp player_glyph_filter(:depleted), do: "url(#user-glow)"
  defp player_glyph_filter(:low), do: "url(#user-glow)"
  defp player_glyph_filter(:normal), do: "url(#self-glow)"
  defp player_glyph_filter(:elevated), do: "url(#self-glow)"
  defp player_glyph_filter(:radiant), do: "url(#self-glow)"
  defp player_glyph_filter(_), do: "url(#self-glow)"

  defp player_glyph_opacity(:depleted), do: 0.6
  defp player_glyph_opacity(:low), do: 0.75
  defp player_glyph_opacity(:normal), do: 1.0
  defp player_glyph_opacity(:elevated), do: 1.0
  defp player_glyph_opacity(:radiant), do: 1.0
  defp player_glyph_opacity(_), do: 1.0

  defp player_glyph_color(base_color, :depleted), do: desaturate_color(base_color)
  defp player_glyph_color(base_color, _), do: base_color

  # Simple desaturation - blend toward gray
  defp desaturate_color(hex) when is_binary(hex) do
    # Parse hex color
    hex = String.trim_leading(hex, "#")
    case Integer.parse(hex, 16) do
      {value, ""} when byte_size(hex) == 6 ->
        r = Bitwise.band(Bitwise.bsr(value, 16), 0xFF)
        g = Bitwise.band(Bitwise.bsr(value, 8), 0xFF)
        b = Bitwise.band(value, 0xFF)
        # Blend toward gray (desaturate by 50%)
        gray = div(r + g + b, 3)
        r2 = div(r + gray, 2)
        g2 = div(g + gray, 2)
        b2 = div(b + gray, 2)
        "##{Integer.to_string(r2, 16) |> String.pad_leading(2, "0")}#{Integer.to_string(g2, 16) |> String.pad_leading(2, "0")}#{Integer.to_string(b2, 16) |> String.pad_leading(2, "0")}"
      _ ->
        hex
    end
  end
  defp desaturate_color(color), do: color

  # Text color based on brightness - darker when far, brighter when close
  defp text_color_for_brightness(brightness) when brightness >= 0.8, do: "#e8e0d5"
  defp text_color_for_brightness(brightness) when brightness >= 0.6, do: "#c4b8a8"
  defp text_color_for_brightness(brightness) when brightness >= 0.4, do: "#8a7d6d"
  defp text_color_for_brightness(brightness) when brightness >= 0.25, do: "#5a4f42"
  defp text_color_for_brightness(_brightness), do: "#3a3530"

  defp truncate_title(title, max_length) do
    if String.length(title) > max_length do
      String.slice(title, 0, max_length - 1) <> "…"
    else
      title
    end
  end

  # Node shape component
  attr :node, :map, required: true
  attr :color, :string, required: true
  attr :selected, :boolean, default: false
  # Node shapes - centered at 0,0, brightness controlled by parent group
  defp node_shape(assigns) do
    ~H"""
    <g
      class="cursor-pointer"
      phx-click="select_node"
      phx-value-id={@node.id}
    >
      <!-- Selection ring (when selected) -->
      <%= if @selected do %>
        <circle
          r="38"
          fill="none"
          stroke="#c9a962"
          stroke-width="2"
          opacity="0.8"
          class="animate-breathe"
        />
        <circle
          r="42"
          fill="none"
          stroke="#c9a962"
          stroke-width="1"
          opacity="0.4"
          stroke-dasharray="4,4"
          class="animate-spin-slow"
        />
      <% end %>

      <%= case @node.glyph_shape do %>
        <% "hexagon" -> %>
          <polygon
            points="0,-20 17,-10 17,10 0,20 -17,10 -17,-10"
            fill={@color}
            filter="url(#node-glow)"
          />
        <% "circle" -> %>
          <circle
            r="18"
            fill={@color}
            filter="url(#node-glow)"
          />
        <% "square" -> %>
          <rect
            x="-15" y="-15"
            width="30" height="30"
            fill={@color}
            filter="url(#node-glow)"
          />
        <% _ -> %>
          <circle
            r="18"
            fill={@color}
            filter="url(#node-glow)"
          />
      <% end %>
    </g>
    """
  end

  # User glyph component
  attr :shape, :string, required: true
  attr :color, :string, required: true
  attr :pulse, :boolean, default: false
  defp user_glyph(assigns) do
    ~H"""
    <g class={if @pulse, do: "animate-pulse", else: ""}>
      <%= case @shape do %>
        <% "circle" -> %>
          <circle r="8" fill={@color} opacity="0.9" />
        <% "triangle" -> %>
          <polygon points="0,-10 8.66,5 -8.66,5" fill={@color} opacity="0.9" />
        <% "square" -> %>
          <rect x="-6" y="-6" width="12" height="12" fill={@color} opacity="0.9" />
        <% "diamond" -> %>
          <polygon points="0,-8 8,0 0,8 -8,0" fill={@color} opacity="0.9" />
        <% "hexagon" -> %>
          <polygon points="6,0 3,5.2 -3,5.2 -6,0 -3,-5.2 3,-5.2" fill={@color} opacity="0.9" />
        <% "pentagon" -> %>
          <polygon points="0,-7 6.7,-2.2 4.1,5.7 -4.1,5.7 -6.7,-2.2" fill={@color} opacity="0.9" />
        <% _ -> %>
          <circle r="8" fill={@color} opacity="0.9" />
      <% end %>
    </g>
    """
  end

  defp viewbox(viewport) do
    width = 1000 / viewport.zoom
    height = 600 / viewport.zoom
    x = viewport.x - width / 2
    y = viewport.y - height / 2
    "#{x} #{y} #{width} #{height}"
  end

  defp error_message(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.map(fn {k, v} -> "#{k}: #{Enum.join(v, ", ")}" end)
    |> Enum.join("; ")
  end

  # Resonance meter component for grid UI
  attr :user, :map, required: true
  defp resonance_meter(assigns) do
    level = Resonance.resonance_level(assigns.user)
    state = Resonance.resonance_state(assigns.user)
    percentage = Resonance.resonance_percentage(assigns.user)

    assigns =
      assigns
      |> assign(:level, level)
      |> assign(:state, state)
      |> assign(:percentage, percentage)

    ~H"""
    <div class="flex items-center gap-3">
      <!-- Resonance bar -->
      <div class="relative">
        <div class="w-24 h-1.5 bg-[#1a1714] overflow-hidden">
          <div
            class={[
              "h-full transition-all duration-500",
              resonance_bar_class(@level)
            ]}
            style={"width: #{@percentage}%"}
          >
          </div>
        </div>
        <!-- Level indicator dots -->
        <div class="absolute top-0 left-0 right-0 flex justify-between -mt-0.5">
          <div class="w-0.5 h-2.5 bg-[#2a2522]"></div>
          <div class="w-0.5 h-2.5 bg-[#2a2522]" style="left: 30%"></div>
          <div class="w-0.5 h-2.5 bg-[#2a2522]" style="left: 70%"></div>
          <div class="w-0.5 h-2.5 bg-[#2a2522]"></div>
        </div>
      </div>
      <!-- State text -->
      <span class={["text-[10px] uppercase tracking-wider", resonance_text_class(@level)]}>
        <%= @state %>
      </span>
      <!-- Warning indicator for low resonance -->
      <%= if @level in [:depleted, :low] do %>
        <div class="w-1.5 h-1.5 rounded-full bg-[#d4756a] animate-pulse"></div>
      <% end %>
    </div>
    """
  end

  defp resonance_bar_class(:depleted), do: "bg-[#d4756a]"
  defp resonance_bar_class(:low), do: "bg-[#c9a962]/60"
  defp resonance_bar_class(:normal), do: "bg-[#8a7d6d]"
  defp resonance_bar_class(:elevated), do: "bg-[#8b9a7d]"
  defp resonance_bar_class(:radiant), do: "bg-gradient-to-r from-[#c9a962] to-[#dba76f]"
  defp resonance_bar_class(_), do: "bg-[#5a4f42]"

  defp resonance_text_class(:depleted), do: "text-[#d4756a]"
  defp resonance_text_class(:low), do: "text-[#c9a962]/70"
  defp resonance_text_class(:normal), do: "text-[#5a4f42]"
  defp resonance_text_class(:elevated), do: "text-[#8b9a7d]"
  defp resonance_text_class(:radiant), do: "text-[#c9a962]"
  defp resonance_text_class(_), do: "text-[#5a4f42]"

  # Resonance change toast component
  attr :toast, :map, required: true
  defp resonance_toast(assigns) do
    is_positive = assigns.toast.amount > 0
    reason_text = format_reason(assigns.toast.reason)

    assigns =
      assigns
      |> assign(:is_positive, is_positive)
      |> assign(:reason_text, reason_text)

    ~H"""
    <div class={[
      "px-4 py-2 border backdrop-blur-sm animate-slide-in-right",
      if(@is_positive,
        do: "bg-[#8b9a7d]/20 border-[#8b9a7d]/40 text-[#8b9a7d]",
        else: "bg-[#d4756a]/20 border-[#d4756a]/40 text-[#d4756a]"
      )
    ]}>
      <div class="flex items-center gap-2 text-xs">
        <span class="font-medium">
          <%= if @is_positive, do: "+", else: "" %><%= @toast.amount %>
        </span>
        <span class="opacity-70"><%= @reason_text %></span>
      </div>
    </div>
    """
  end

  defp format_reason(:affirm_received), do: "Someone affirmed you"
  defp format_reason(:dismiss_received), do: "Someone dismissed you"
  defp format_reason(:message_replied), do: "Your message got a reply"
  defp format_reason(:node_visited), do: "Someone visited your node"
  defp format_reason(:remembered), do: "Someone remembered you"
  defp format_reason(reason) when is_atom(reason), do: reason |> Atom.to_string() |> String.replace("_", " ")
  defp format_reason(reason) when is_binary(reason), do: String.replace(reason, "_", " ")
  defp format_reason(_), do: "Resonance changed"
end
