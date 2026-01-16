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
  def handle_info({:presence_diff, diff}, socket) do
    users = Presence.handle_diff(socket.assigns.users, diff)
    {:noreply, assign(socket, :users, users)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="grid-container"
      class="fixed inset-0 bg-grid-base overflow-hidden cursor-move select-none"
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
          <!-- Grid pattern -->
          <pattern id="grid-pattern" width="50" height="50" patternUnits="userSpaceOnUse">
            <path d="M 50 0 L 0 0 0 50" fill="none" stroke="rgba(139, 115, 85, 0.1)" stroke-width="0.5"/>
          </pattern>

          <!-- Glow filter for nodes -->
          <filter id="glow" x="-50%" y="-50%" width="200%" height="200%">
            <feGaussianBlur stdDeviation="3" result="coloredBlur"/>
            <feMerge>
              <feMergeNode in="coloredBlur"/>
              <feMergeNode in="SourceGraphic"/>
            </feMerge>
          </filter>
        </defs>

        <!-- Background grid -->
        <rect width="10000" height="10000" x="-5000" y="-5000" fill="url(#grid-pattern)" />

        <!-- Topic nodes -->
        <%= for node <- @nodes do %>
          <g
            class="node cursor-pointer transition-transform hover:scale-110"
            transform={"translate(#{node.position_x}, #{node.position_y})"}
          >
            <.node_shape node={node} />
            <text
              y="35"
              text-anchor="middle"
              class="fill-text-secondary text-xs font-medium pointer-events-none"
              style="font-size: 10px;"
            >
              <%= node.title %>
            </text>
          </g>
        <% end %>

        <!-- Other users -->
        <%= for {_id, user_presence} <- @users do %>
          <%= if user_presence.user_id != @user.id do %>
            <g transform={"translate(#{user_presence.x || 0}, #{user_presence.y || 0})"}>
              <.user_glyph shape={user_presence.glyph_shape} color={user_presence.glyph_color} />
            </g>
          <% end %>
        <% end %>

        <!-- Current user (you) -->
        <g id="current-user" transform={"translate(#{@viewport.x * -1}, #{@viewport.y * -1})"}>
          <.user_glyph shape={@user.glyph_shape} color={@user.glyph_color} pulse={true} />
        </g>
      </svg>

      <!-- UI Overlay -->
      <div class="absolute bottom-6 left-6 text-text-muted text-sm font-mono opacity-60">
        <span class="text-text-secondary"><%= length(@nodes) %></span> nodes
        · <span class="text-text-secondary"><%= map_size(@users) %></span> wandering
      </div>

      <div class="absolute top-6 right-6 text-text-muted text-xs font-mono opacity-40">
        <%= Float.round(@viewport.zoom * 100, 0) %>%
      </div>
    </div>
    """
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
