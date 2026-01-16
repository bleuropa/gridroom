defmodule GridroomWeb.NodeLive do
  use GridroomWeb, :live_view

  alias Gridroom.{Grid, Accounts}

  @impl true
  def mount(%{"id" => id}, session, socket) do
    node = Grid.get_node!(id)

    # Get or create user from session
    session_id = session["_csrf_token"] || Ecto.UUID.generate()
    {:ok, user} = Accounts.get_or_create_user(session_id)

    # Subscribe to messages for this node
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Gridroom.PubSub, "node:#{id}")
    end

    # Load messages
    messages = Grid.list_messages_for_node(id, limit: 100)

    {:ok,
     socket
     |> assign(:node, node)
     |> assign(:user, user)
     |> assign(:messages, messages)
     |> assign(:message_form, to_form(%{"content" => ""}))
     |> assign(:page_title, node.title)}
  end

  @impl true
  def handle_event("send_message", %{"content" => content}, socket) when content != "" do
    node = socket.assigns.node
    user = socket.assigns.user

    case Grid.create_message(%{
      content: String.trim(content),
      node_id: node.id,
      user_id: user.id
    }) do
      {:ok, _message} ->
        {:noreply, assign(socket, :message_form, to_form(%{"content" => ""}))}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  def handle_event("send_message", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_info({:new_message, message}, socket) do
    messages = socket.assigns.messages ++ [message]
    {:noreply, assign(socket, :messages, messages)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-grid-base flex flex-col">
      <!-- Header -->
      <header class="border-b border-grid-line px-6 py-4 flex items-center gap-4">
        <a href="/" class="text-text-muted hover:text-text-primary transition-colors">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"/>
          </svg>
        </a>
        <div>
          <h1 class="text-xl font-medium text-text-primary"><%= @node.title %></h1>
          <p class="text-sm text-text-muted"><%= @node.description %></p>
        </div>
        <div class="ml-auto flex items-center gap-2">
          <.node_type_badge type={@node.node_type} />
        </div>
      </header>

      <!-- Messages -->
      <div
        id="messages"
        class="flex-1 overflow-y-auto px-6 py-4 space-y-4"
        phx-hook="ScrollToBottom"
      >
        <%= if Enum.empty?(@messages) do %>
          <div class="text-center text-text-muted py-12">
            <p class="text-lg">This space is quiet.</p>
            <p class="text-sm mt-2">Be the first to speak.</p>
          </div>
        <% else %>
          <%= for message <- @messages do %>
            <.message_bubble message={message} current_user={@user} />
          <% end %>
        <% end %>
      </div>

      <!-- Input -->
      <div class="border-t border-grid-line px-6 py-4">
        <.form for={@message_form} phx-submit="send_message" class="flex gap-3">
          <div class="flex-1 relative">
            <input
              type="text"
              name="content"
              value={@message_form[:content].value}
              placeholder="Say something..."
              class="w-full bg-grid-surface border border-grid-line rounded-lg px-4 py-3 text-text-primary placeholder-text-muted focus:outline-none focus:border-accent-warm transition-colors"
              autocomplete="off"
            />
          </div>
          <button
            type="submit"
            class="px-6 py-3 bg-accent-warm text-grid-base rounded-lg font-medium hover:bg-accent-warm/90 transition-colors"
          >
            Speak
          </button>
        </.form>
      </div>
    </div>
    """
  end

  attr :type, :string, required: true
  defp node_type_badge(assigns) do
    colors = %{
      "discussion" => "bg-accent-warm/20 text-accent-warm",
      "question" => "bg-blue-500/20 text-blue-400",
      "debate" => "bg-red-500/20 text-red-400",
      "quiet" => "bg-gray-500/20 text-gray-400"
    }

    assigns = assign(assigns, :colors, Map.get(colors, assigns.type, "bg-gray-500/20 text-gray-400"))

    ~H"""
    <span class={"px-2 py-1 rounded text-xs font-medium #{@colors}"}>
      <%= @type %>
    </span>
    """
  end

  attr :message, :map, required: true
  attr :current_user, :map, required: true
  defp message_bubble(assigns) do
    is_own = assigns.message.user_id == assigns.current_user.id
    assigns = assign(assigns, :is_own, is_own)

    ~H"""
    <div class={"flex gap-3 #{if @is_own, do: "flex-row-reverse"}"}>
      <!-- User glyph -->
      <div class="flex-shrink-0">
        <svg width="32" height="32" viewBox="-10 -10 20 20">
          <.message_glyph user={@message.user} />
        </svg>
      </div>

      <!-- Message content -->
      <div class={"max-w-md px-4 py-2 rounded-lg #{if @is_own, do: "bg-accent-warm/20", else: "bg-grid-surface"}"}>
        <p class="text-text-primary"><%= @message.content %></p>
        <p class="text-xs text-text-muted mt-1">
          <%= Calendar.strftime(@message.inserted_at, "%H:%M") %>
        </p>
      </div>
    </div>
    """
  end

  defp message_glyph(assigns) do
    user = assigns.user || %{glyph_shape: "circle", glyph_color: "#888"}
    assigns = assign(assigns, :user, user)

    ~H"""
    <%= case @user.glyph_shape do %>
      <% "circle" -> %>
        <circle r="8" fill={@user.glyph_color} />
      <% "triangle" -> %>
        <polygon points="0,-10 8.66,5 -8.66,5" fill={@user.glyph_color} />
      <% "square" -> %>
        <rect x="-6" y="-6" width="12" height="12" fill={@user.glyph_color} />
      <% "diamond" -> %>
        <polygon points="0,-8 8,0 0,8 -8,0" fill={@user.glyph_color} />
      <% "hexagon" -> %>
        <polygon points="6,0 3,5.2 -3,5.2 -6,0 -3,-5.2 3,-5.2" fill={@user.glyph_color} />
      <% "pentagon" -> %>
        <polygon points="0,-7 6.7,-2.2 4.1,5.7 -4.1,5.7 -6.7,-2.2" fill={@user.glyph_color} />
      <% _ -> %>
        <circle r="8" fill={@user.glyph_color || "#888"} />
    <% end %>
    """
  end
end
