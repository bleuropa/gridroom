defmodule GridroomWeb.GridLive do
  use GridroomWeb, :live_view

  alias Gridroom.{Grid, Accounts}
  alias GridroomWeb.Presence

  @impl true
  def mount(_params, session, socket) do
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

    # Load initial nodes
    nodes = Grid.list_nodes()

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:nodes, nodes)
     |> assign(:viewport, %{x: 0, y: 0, zoom: 1.0})
     |> assign(:users, %{})
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
  def handle_event("update_position", %{"x" => x, "y" => y}, socket) do
    user = socket.assigns.user
    Presence.update_position(self(), user, x, y)
    {:noreply, socket}
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
    users = Presence.handle_diff(socket.assigns.users, diff)
    {:noreply, assign(socket, :users, users)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="grid-container"
      class="fixed inset-0 overflow-hidden cursor-move select-none"
      phx-hook="GridCanvas"
      data-viewport-x={@viewport.x}
      data-viewport-y={@viewport.y}
      data-viewport-zoom={@viewport.zoom}
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
          <g
            class="node"
            transform={"translate(#{node.position_x}, #{node.position_y})"}
            style={"animation-delay: #{rem(index, 5) * -0.8}s;"}
          >
            <!-- Outer glow ring -->
            <circle
              r="35"
              fill="none"
              stroke={node_type_color(node.node_type)}
              stroke-width="0.5"
              opacity="0.2"
              class="animate-breathe"
            />

            <!-- Node shape with link -->
            <a href={~p"/node/#{node.id}"}>
              <.node_shape node={node} />
            </a>

            <!-- Label with backdrop -->
            <text
              y="42"
              text-anchor="middle"
              class="node-label pointer-events-none"
              fill="#c4b8a8"
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

        <!-- Current user (you) - centered -->
        <g
          id="current-user"
          class="user-glyph-self"
          transform={"translate(#{@viewport.x * -1}, #{@viewport.y * -1})"}
          filter="url(#self-glow)"
        >
          <.user_glyph shape={@user.glyph_shape} color={@user.glyph_color} pulse={true} />
          <!-- Subtle pulse ring -->
          <circle r="16" fill="none" stroke={@user.glyph_color} stroke-width="0.5" opacity="0.3" class="animate-pulse-glow" />
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

      <!-- Hint overlay for new users -->
      <%= if map_size(@users) == 0 do %>
        <div class="absolute bottom-6 right-6 ui-overlay text-[#3a3530] max-w-xs text-right">
          <p class="text-xs leading-relaxed">drag to explore · click nodes to enter · others will appear</p>
        </div>
      <% end %>
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

  defp node_type_color("discussion"), do: "#c9a962"
  defp node_type_color("question"), do: "#7eb8da"
  defp node_type_color("debate"), do: "#d4756a"
  defp node_type_color("quiet"), do: "#8b9a7d"
  defp node_type_color(_), do: "#c9a962"

  defp truncate_title(title, max_length) do
    if String.length(title) > max_length do
      String.slice(title, 0, max_length - 1) <> "…"
    else
      title
    end
  end

  # Node shape component
  attr :node, :map, required: true
  defp node_shape(assigns) do
    ~H"""
    <a href={~p"/node/#{@node.id}"} class="block">
      <%= case @node.glyph_shape do %>
        <% "hexagon" -> %>
          <polygon
            points="20,0 40,12 40,36 20,48 0,36 0,12"
            fill={@node.glyph_color}
            opacity="0.8"
            filter="url(#glow)"
          />
        <% "circle" -> %>
          <circle
            r="20"
            fill={@node.glyph_color}
            opacity="0.8"
            filter="url(#glow)"
          />
        <% "square" -> %>
          <rect
            x="-18" y="-18"
            width="36" height="36"
            fill={@node.glyph_color}
            opacity="0.8"
            filter="url(#glow)"
          />
        <% _ -> %>
          <circle
            r="20"
            fill={@node.glyph_color}
            opacity="0.8"
            filter="url(#glow)"
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
