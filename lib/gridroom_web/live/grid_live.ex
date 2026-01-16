defmodule GridroomWeb.GridLive do
  use GridroomWeb, :live_view

  alias Gridroom.{Grid, Accounts}
  alias GridroomWeb.Presence

  # Node entry constants
  @entry_threshold 40
  @dwell_time_ms 1500
  @dwell_tick_ms 50

  @impl true
  def mount(params, session, socket) do
    # Get or create user from session
    session_id = session["_csrf_token"] || Ecto.UUID.generate()
    {:ok, user} = Accounts.get_or_create_user(session_id)

    # Subscribe to presence updates
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Gridroom.PubSub, "grid:presence")
      Presence.track_user(self(), user)
    end

    # Seed nodes if needed (first time setup)
    Grid.seed_initial_nodes!()

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
     |> assign(:nodes, nodes)
     |> assign(:player, player_pos)
     |> assign(:viewport, %{x: player_pos.x, y: player_pos.y, zoom: 1.0})
     |> assign(:users, %{})
     |> assign(:entering_node, nil)
     |> assign(:can_enter_node, can_enter)
     |> assign(:dwelling_node, nil)
     |> assign(:dwell_progress, 0.0)
     |> assign(:page_title, "Gridroom")}
  end

  @impl true
  def handle_event("pan", %{"dx" => dx, "dy" => dy}, socket) do
    viewport = socket.assigns.viewport
    new_viewport = %{viewport | x: viewport.x + dx, y: viewport.y + dy}
    {:noreply, assign(socket, :viewport, new_viewport)}
  end

  @impl true
  def handle_event("zoom", %{"delta" => delta, "x" => _x, "y" => _y}, socket) do
    viewport = socket.assigns.viewport
    zoom_factor = if delta > 0, do: 0.9, else: 1.1
    new_zoom = max(0.25, min(4.0, viewport.zoom * zoom_factor))
    {:noreply, assign(socket, :viewport, %{viewport | zoom: new_zoom})}
  end

  @impl true
  def handle_event("move", %{"dx" => dx, "dy" => dy}, socket) do
    player = socket.assigns.player
    speed = 8 / socket.assigns.viewport.zoom
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

    {:noreply, assign(socket, :player, new_player)}
  end

  @impl true
  def handle_event("update_position", %{"x" => x, "y" => y}, socket) do
    user = socket.assigns.user
    Presence.update_position(self(), user, x, y)
    {:noreply, socket}
  end

  @impl true
  def handle_event("enter_node", %{"id" => node_id}, socket) do
    # Trigger the entry animation
    {:noreply,
     socket
     |> assign(:entering_node, node_id)
     |> push_event("entering_node", %{node_id: node_id})}
  end

  @impl true
  def handle_event("navigate_to_node", %{"id" => node_id}, socket) do
    {:noreply, push_navigate(socket, to: "/node/#{node_id}")}
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
    users = Presence.handle_diff(socket.assigns.users, diff)
    {:noreply, assign(socket, :users, users)}
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

        <!-- Ambient center glow -->
        <ellipse cx="0" cy="0" rx="400" ry="300" fill="url(#ambient-glow)" class="animate-breathe" />

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
          <g
            class={"node node-activity-#{activity.level}"}
            data-node-id={node.id}
            transform={"translate(#{node.position_x}, #{node.position_y})"}
            style={"animation-delay: #{rem(index, 5) * -0.8}s;"}
          >
            <!-- Activity rings - more rings = more activity -->
            <%= if activity.level == :buzzing do %>
              <circle r="50" fill="none" stroke={node_type_color(node.node_type)} stroke-width="0.3" opacity="0.15" class="animate-pulse-ring" />
              <circle r="45" fill="none" stroke={node_type_color(node.node_type)} stroke-width="0.4" opacity="0.2" class="animate-pulse-ring" style="animation-delay: -0.3s;" />
            <% end %>
            <%= if activity.level in [:active, :buzzing] do %>
              <circle r="40" fill="none" stroke={node_type_color(node.node_type)} stroke-width="0.5" opacity="0.25" class="animate-pulse-ring" style="animation-delay: -0.6s;" />
            <% end %>

            <!-- Outer glow ring - intensity based on activity -->
            <circle
              r="35"
              fill="none"
              stroke={node_type_color(node.node_type)}
              stroke-width={activity_stroke_width(activity.level)}
              opacity={activity_opacity(activity.level)}
              class={if activity.level in [:active, :buzzing], do: "animate-breathe-fast", else: "animate-breathe"}
            />

            <!-- Node shape with link -->
            <a href={~p"/node/#{node.id}"}>
              <.node_shape node={node} activity_level={activity.level} />
            </a>

            <!-- Activity indicator dot -->
            <%= if activity.count > 0 do %>
              <circle
                cx="18"
                cy="-18"
                r="4"
                fill={activity_dot_color(activity.level)}
                class={if activity.level == :buzzing, do: "animate-pulse", else: ""}
              />
              <%= if activity.count > 1 do %>
                <text
                  x="18"
                  y="-15"
                  text-anchor="middle"
                  fill="#0d0b0a"
                  style="font-size: 6px; font-weight: bold;"
                >
                  <%= min(activity.count, 99) %>
                </text>
              <% end %>
            <% end %>

            <!-- Label with backdrop -->
            <text
              y="42"
              text-anchor="middle"
              class="node-label pointer-events-none"
              fill={if activity.level == :dormant, do: "#6a5f52", else: "#c4b8a8"}
              style="font-size: 11px; font-family: 'Space Grotesk', sans-serif;"
            >
              <%= truncate_title(node.title, 24) %>
            </text>
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
        <g
          id="current-user"
          class="user-glyph-self"
          transform={"translate(#{@player.x}, #{@player.y})"}
          filter="url(#self-glow)"
        >
          <.user_glyph shape={@user.glyph_shape} color={@user.glyph_color} pulse={true} />
          <!-- Subtle pulse ring -->
          <circle r="16" fill="none" stroke={@user.glyph_color} stroke-width="0.5" opacity="0.3" class="animate-pulse-glow" />
          <!-- Movement indicator -->
          <circle r="20" fill="none" stroke={@user.glyph_color} stroke-width="0.3" opacity="0.15" stroke-dasharray="2,4" class="animate-spin-slow" />

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
        <div class="flex items-center gap-2">
          <div class="w-2 h-2 rounded-full bg-[#c9a962] animate-pulse"></div>
          <span class="ui-stat"><%= length(@nodes) %> nodes</span>
        </div>
        <div class="w-px h-3 bg-[#2a2522]"></div>
        <div class="flex items-center gap-2">
          <div class="w-2 h-2 rounded-full" style={"background-color: #{@user.glyph_color};"}></div>
          <span class="ui-stat"><%= map_size(@users) + 1 %> present</span>
        </div>
      </div>

      <!-- UI Overlay - Top Right -->
      <div class="ui-overlay absolute top-6 right-6 flex items-center gap-3">
        <span class="ui-stat"><%= Float.round(@viewport.zoom * 100, 0) |> trunc %>%</span>
      </div>

      <!-- UI Overlay - Top Left - Title -->
      <div class="absolute top-6 left-6">
        <h1 class="text-[#5a4f42] text-sm tracking-[0.2em] uppercase font-light">Gridroom</h1>
      </div>

      <!-- Controls hint -->
      <div class="absolute bottom-6 right-6 ui-overlay text-[#3a3530] max-w-xs text-right">
        <p class="text-xs leading-relaxed opacity-60">
          <span class="text-[#5a4f42]">WASD</span> move ·
          <span class="text-[#5a4f42]">drag</span> pan ·
          <span class="text-[#5a4f42]">space</span> center
        </p>
      </div>
    </div>
    """
  end

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

  # Activity-based styling
  defp activity_stroke_width(:dormant), do: "0.3"
  defp activity_stroke_width(:quiet), do: "0.5"
  defp activity_stroke_width(:active), do: "0.8"
  defp activity_stroke_width(:buzzing), do: "1.2"

  defp activity_opacity(:dormant), do: "0.1"
  defp activity_opacity(:quiet), do: "0.2"
  defp activity_opacity(:active), do: "0.35"
  defp activity_opacity(:buzzing), do: "0.5"

  defp activity_dot_color(:quiet), do: "#6a8a5a"
  defp activity_dot_color(:active), do: "#c9a962"
  defp activity_dot_color(:buzzing), do: "#e8c547"
  defp activity_dot_color(_), do: "#555"

  defp node_opacity(:dormant), do: "0.5"
  defp node_opacity(:quiet), do: "0.7"
  defp node_opacity(:active), do: "0.85"
  defp node_opacity(:buzzing), do: "1.0"

  defp truncate_title(title, max_length) do
    if String.length(title) > max_length do
      String.slice(title, 0, max_length - 1) <> "…"
    else
      title
    end
  end

  # Node shape component
  attr :node, :map, required: true
  attr :activity_level, :atom, default: :dormant
  defp node_shape(assigns) do
    opacity = node_opacity(assigns.activity_level)
    assigns = assign(assigns, :opacity, opacity)

    ~H"""
    <a href={~p"/node/#{@node.id}"} class="block">
      <%= case @node.glyph_shape do %>
        <% "hexagon" -> %>
          <polygon
            points="20,0 40,12 40,36 20,48 0,36 0,12"
            fill={@node.glyph_color}
            opacity={@opacity}
            filter="url(#node-glow)"
          />
        <% "circle" -> %>
          <circle
            r="20"
            fill={@node.glyph_color}
            opacity={@opacity}
            filter="url(#node-glow)"
          />
        <% "square" -> %>
          <rect
            x="-18" y="-18"
            width="36" height="36"
            fill={@node.glyph_color}
            opacity={@opacity}
            filter="url(#node-glow)"
          />
        <% _ -> %>
          <circle
            r="20"
            fill={@node.glyph_color}
            opacity={@opacity}
            filter="url(#node-glow)"
          />
      <% end %>
    </a>
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
end
