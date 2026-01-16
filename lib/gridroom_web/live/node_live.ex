defmodule GridroomWeb.NodeLive do
  use GridroomWeb, :live_view

  alias Gridroom.{Grid, Accounts, Connections, Resonance}
  alias GridroomWeb.Presence

  @impl true
  def mount(%{"id" => id}, session, socket) do
    node = Grid.get_node!(id)

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

    # Check if user has enough resonance to enter
    if Resonance.should_kick?(user) do
      {:ok,
       socket
       |> put_flash(:error, "Your resonance is too low to enter this space. Contribute positively elsewhere to rebuild.")
       |> push_navigate(to: ~p"/")}
    else
      mount_node(socket, node, user, id)
    end
  end

  defp mount_node(socket, node, user, id) do
    # Subscribe to messages and presence for this node
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Gridroom.PubSub, "node:#{id}")
      Presence.subscribe_to_node(id)
      Presence.track_user_in_node(self(), user, id)

      # Record visit for activity tracking
      Connections.record_visit(user, id)
    end

    # Load messages and current presence
    messages = Grid.list_messages_for_node(id, limit: 100)
    present_users = if connected?(socket), do: presence_to_map(Presence.list_users_in_node(id)), else: %{}

    # Load remembered users for recognition highlighting
    remembered_user_ids =
      user
      |> Connections.list_remembered_users()
      |> Enum.map(& &1.id)
      |> MapSet.new()

    {:ok,
     socket
     |> assign(:node, node)
     |> assign(:user, user)
     |> assign(:messages, messages)
     |> assign(:present_users, present_users)
     |> assign(:remembered_user_ids, remembered_user_ids)
     |> assign(:message_form, to_form(%{"content" => ""}))
     |> assign(:page_title, node.title)
     |> assign(:og_title, "#{node.title} - Gridroom")
     |> assign(:og_description, node.description || "Join this conversation at Gridroom")
     |> assign(:show_copied_toast, false)
     |> assign(:typing, false)
     |> assign(:selected_user, nil)
     |> assign(:selected_user_activity, [])
     |> assign(:is_remembered, false)
     |> assign(:kick_warning, nil)}
  end

  defp presence_to_map(presence_list) do
    Enum.reduce(presence_list, %{}, fn {id, %{metas: [meta | _]}}, acc ->
      Map.put(acc, id, meta)
    end)
  end

  @impl true
  def handle_event("send_message", %{"content" => content}, socket) when content != "" do
    node = socket.assigns.node
    user = socket.assigns.user

    # Stop typing indicator when sending
    if socket.assigns.typing do
      Presence.set_typing(self(), user, node.id, false)
    end

    case Grid.create_message(%{
      content: String.trim(content),
      node_id: node.id,
      user_id: user.id
    }) do
      {:ok, _message} ->
        {:noreply,
         socket
         |> assign(:message_form, to_form(%{"content" => ""}))
         |> assign(:typing, false)
         |> push_event("clear_input", %{id: "message-input"})}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  def handle_event("send_message", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_event("typing_start", _params, socket) do
    if not socket.assigns.typing do
      Presence.set_typing(self(), socket.assigns.user, socket.assigns.node.id, true)
    end
    {:noreply, assign(socket, :typing, true)}
  end

  @impl true
  def handle_event("typing_stop", _params, socket) do
    if socket.assigns.typing do
      Presence.set_typing(self(), socket.assigns.user, socket.assigns.node.id, false)
    end
    {:noreply, assign(socket, :typing, false)}
  end

  @impl true
  def handle_event("copy_share_url", _params, socket) do
    # The actual copy happens in JS, we just show the toast
    Process.send_after(self(), :hide_copied_toast, 2000)
    {:noreply, assign(socket, :show_copied_toast, true)}
  end

  @impl true
  def handle_event("select_user", %{"id" => user_id}, socket) do
    # Don't open sidebar for self
    if user_id == socket.assigns.user.id do
      {:noreply, socket}
    else
      selected_user = Accounts.get_user(user_id)
      activity = Connections.recent_activity(user_id, limit: 5)
      is_remembered = Connections.remembers?(socket.assigns.user, user_id)

      {:noreply,
       socket
       |> assign(:selected_user, selected_user)
       |> assign(:selected_user_activity, activity)
       |> assign(:is_remembered, is_remembered)}
    end
  end

  @impl true
  def handle_event("close_profile", _params, socket) do
    {:noreply,
     socket
     |> assign(:selected_user, nil)
     |> assign(:selected_user_activity, [])
     |> assign(:is_remembered, false)}
  end

  @impl true
  def handle_event("remember_user", %{"id" => friend_id}, socket) do
    user = socket.assigns.user
    friend = Accounts.get_user(friend_id)
    node_id = socket.assigns.node.id

    case Connections.remember_user(user, friend, met_in_node_id: node_id) do
      {:ok, _connection} ->
        updated_ids = MapSet.put(socket.assigns.remembered_user_ids, friend_id)
        {:noreply,
         socket
         |> assign(:is_remembered, true)
         |> assign(:remembered_user_ids, updated_ids)}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("forget_user", %{"id" => friend_id}, socket) do
    Connections.forget_user(socket.assigns.user, friend_id)
    updated_ids = MapSet.delete(socket.assigns.remembered_user_ids, friend_id)
    {:noreply,
     socket
     |> assign(:is_remembered, false)
     |> assign(:remembered_user_ids, updated_ids)}
  end

  @impl true
  def handle_event("affirm_message", %{"id" => message_id}, socket) do
    message = Grid.get_message!(message_id)
    user = socket.assigns.user

    case Resonance.affirm_message(user, message) do
      {:ok, _updated_user} ->
        {:noreply,
         socket
         |> assign(:feedback_given, %{message_id: message_id, type: :affirm})
         |> push_event("feedback_given", %{message_id: message_id, type: "affirm"})}

      {:error, :cooldown_active} ->
        {:noreply, socket}

      {:error, :cannot_feedback_self} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("dismiss_message", %{"id" => message_id}, socket) do
    message = Grid.get_message!(message_id)
    user = socket.assigns.user

    case Resonance.dismiss_message(user, message) do
      {:ok, _updated_user} ->
        {:noreply,
         socket
         |> assign(:feedback_given, %{message_id: message_id, type: :dismiss})
         |> push_event("feedback_given", %{message_id: message_id, type: "dismiss"})}

      {:error, :cooldown_active} ->
        {:noreply, socket}

      {:error, :cannot_feedback_self} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info(:hide_copied_toast, socket) do
    {:noreply, assign(socket, :show_copied_toast, false)}
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    messages = socket.assigns.messages ++ [message]
    {:noreply, assign(socket, :messages, messages)}
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
    present_users = Presence.handle_diff(socket.assigns.present_users, diff)
    {:noreply, assign(socket, :present_users, present_users)}
  end

  @impl true
  def handle_info({:resonance_changed, changed_user}, socket) do
    user = socket.assigns.user

    # Update presence data for the changed user
    present_users =
      if Map.has_key?(socket.assigns.present_users, changed_user.id) do
        Map.update!(socket.assigns.present_users, changed_user.id, fn meta ->
          %{meta | resonance: changed_user.resonance}
        end)
      else
        socket.assigns.present_users
      end

    # Check if current user is the one with changed resonance
    socket =
      if user.id == changed_user.id do
        # Update our local user data
        socket = assign(socket, :user, changed_user)

        # Check if we should be kicked
        if Resonance.should_kick?(changed_user) and is_nil(socket.assigns.kick_warning) do
          # Schedule kick after warning period
          Process.send_after(self(), :execute_kick, 5000)

          assign(socket, :kick_warning, %{
            reason: :resonance_depleted,
            countdown: 5
          })
        else
          socket
        end
      else
        socket
      end

    {:noreply, assign(socket, :present_users, present_users)}
  end

  @impl true
  def handle_info(:execute_kick, socket) do
    if socket.assigns.kick_warning do
      {:noreply,
       socket
       |> put_flash(:error, "Your resonance is too low to remain in this space.")
       |> push_navigate(to: ~p"/")}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(:countdown_tick, socket) do
    case socket.assigns.kick_warning do
      %{countdown: c} when c > 1 ->
        Process.send_after(self(), :countdown_tick, 1000)
        {:noreply, assign(socket, :kick_warning, %{socket.assigns.kick_warning | countdown: c - 1})}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-[#0a0908] flex flex-col room-entrance relative" phx-hook="RoomEntrance" id="room-container">
      <!-- Subtle ambient gradient overlay -->
      <div class="absolute inset-0 bg-gradient-to-b from-[#0d0b0a] via-transparent to-[#0d0b0a]/80 pointer-events-none"></div>
      <div class="absolute inset-0 bg-[radial-gradient(ellipse_at_center,_rgba(201,169,98,0.02)_0%,_transparent_70%)] pointer-events-none"></div>

      <!-- Header - Lumon style -->
      <header class="relative z-10 border-b border-[#1a1714] bg-[#0d0b0a]/90 backdrop-blur-sm">
        <div class="px-8 py-5 flex items-center gap-5">
          <a href={"/?from=#{@node.id}"} class="text-[#4a4038] hover:text-[#c9a962] transition-colors duration-300">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M10 19l-7-7m0 0l7-7m-7 7h18"/>
            </svg>
          </a>
          <div class="flex-1">
            <div class="flex items-center gap-3">
              <h1 class="text-lg font-light tracking-wide text-[#e8dcc8]"><%= @node.title %></h1>
              <.node_type_badge type={@node.node_type} />
            </div>
            <%= if @node.description do %>
              <p class="text-sm text-[#5a4f42] mt-1 font-light italic"><%= @node.description %></p>
            <% end %>
          </div>
          <button
            id="share-button"
            phx-click="copy_share_url"
            phx-hook="CopyToClipboard"
            data-copy-text={url(~p"/node/#{@node.id}")}
            class="flex items-center gap-2 px-4 py-2 text-xs uppercase tracking-widest text-[#5a4f42] hover:text-[#c9a962] border border-[#2a2522] hover:border-[#c9a962]/40 transition-all duration-300"
          >
            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M7.217 10.907a2.25 2.25 0 100 2.186m0-2.186c.18.324.283.696.283 1.093s-.103.77-.283 1.093m0-2.186l9.566-5.314m-9.566 7.5l9.566 5.314m0 0a2.25 2.25 0 103.935 2.186 2.25 2.25 0 00-3.935-2.186zm0-12.814a2.25 2.25 0 103.933-2.185 2.25 2.25 0 00-3.933 2.185z"/>
            </svg>
            Share
          </button>
        </div>
        <!-- Subtle bottom highlight line -->
        <div class="absolute bottom-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-[#c9a962]/20 to-transparent"></div>
      </header>

      <!-- Copied toast - Lumon style -->
      <%= if @show_copied_toast do %>
        <div class="fixed top-24 left-1/2 -translate-x-1/2 z-50 animate-fade-in">
          <div class="bg-[#0d0b0a] border border-[#2a2522] px-6 py-3 text-xs tracking-widest uppercase text-[#8a7d6d] shadow-xl shadow-black/50">
            <span class="text-[#c9a962] mr-2">&#x2713;</span> Link copied
          </div>
        </div>
      <% end %>

      <!-- Messages area -->
      <div
        id="messages"
        class="relative z-10 flex-1 overflow-y-auto px-8 py-6"
        phx-hook="ScrollToBottom"
      >
        <%= if Enum.empty?(@messages) do %>
          <div class="flex flex-col items-center justify-center h-full text-center">
            <div class="w-16 h-px bg-gradient-to-r from-transparent via-[#2a2522] to-transparent mb-8"></div>
            <p class="text-[#5a4f42] text-sm uppercase tracking-widest">This space awaits</p>
            <p class="text-[#3a3330] text-xs mt-3 font-light">Be the first to speak</p>
            <div class="w-16 h-px bg-gradient-to-r from-transparent via-[#2a2522] to-transparent mt-8"></div>
          </div>
        <% else %>
          <div class="space-y-5">
            <%= for message <- @messages do %>
              <.message_bubble
                message={message}
                current_user={@user}
                is_recognized={MapSet.member?(@remembered_user_ids, message.user_id)}
              />
            <% end %>
          </div>
        <% end %>
      </div>

      <!-- Bottom section: presence row + input -->
      <div class="relative z-10 border-t border-[#1a1714] bg-[#0d0b0a]/95 backdrop-blur-sm">
        <!-- Presence row - diamond avatars -->
        <div class="px-8 py-4 border-b border-[#1a1714]/50">
          <div class="flex items-center gap-2">
            <span class="text-[#3a3330] text-[10px] uppercase tracking-[0.2em] mr-4">Present</span>
            <div class="flex items-center gap-3">
              <%= for {_id, presence} <- @present_users do %>
                <.presence_diamond
                  presence={presence}
                  is_self={presence.user_id == @user.id}
                  is_recognized={MapSet.member?(@remembered_user_ids, presence.user_id)}
                  on_click={if presence.user_id != @user.id, do: "select_user"}
                />
              <% end %>
            </div>
            <!-- Typing indicator -->
            <% typing_users = Enum.filter(@present_users, fn {id, p} -> p.typing && id != @user.id end) %>
            <%= if length(typing_users) > 0 do %>
              <span class="ml-auto text-[#5a4f42] text-xs tracking-wide animate-pulse">
                <%= typing_text(typing_users) %>
              </span>
            <% end %>
          </div>
        </div>

        <!-- Input area -->
        <div class="px-8 py-5">
          <.form for={@message_form} phx-submit="send_message" class="flex gap-4">
            <div class="flex-1 relative">
              <input
                type="text"
                name="content"
                id="message-input"
                phx-hook="TypingIndicator"
                value={@message_form[:content].value}
                placeholder="Speak..."
                class="w-full bg-[#141210] border border-[#2a2522] px-5 py-3.5 text-[#e8dcc8] placeholder-[#3a3330] focus:outline-none focus:border-[#c9a962]/50 focus:shadow-[0_0_20px_rgba(201,169,98,0.1)] transition-all duration-300 text-sm tracking-wide"
                autocomplete="off"
              />
              <!-- Subtle inner glow on focus via CSS -->
            </div>
            <button
              type="submit"
              class="px-8 py-3.5 bg-gradient-to-b from-[#c9a962] to-[#a68b4d] text-[#0d0b0a] text-xs uppercase tracking-[0.2em] font-medium hover:from-[#d4b46d] hover:to-[#b89a58] transition-all duration-300 shadow-lg shadow-[#c9a962]/20 hover:shadow-[#c9a962]/40"
            >
              Speak
            </button>
          </.form>
        </div>
      </div>

      <!-- Profile sidebar -->
      <%= if @selected_user do %>
        <.user_profile_sidebar
          user={@selected_user}
          activity={@selected_user_activity}
          is_remembered={@is_remembered}
        />
      <% end %>

      <!-- Kick warning overlay -->
      <%= if @kick_warning do %>
        <.kick_warning_overlay warning={@kick_warning} />
      <% end %>
    </div>
    """
  end

  defp kick_warning_overlay(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-black/80 backdrop-blur-sm z-[100] flex items-center justify-center animate-fade-in">
      <div class="bg-[#0d0b0a] border border-[#d4756a]/40 p-8 max-w-md text-center">
        <!-- Warning icon -->
        <div class="w-16 h-16 mx-auto mb-6 relative">
          <svg viewBox="0 0 24 24" class="w-full h-full text-[#d4756a] animate-pulse">
            <path fill="currentColor" d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z" opacity="0"/>
            <path fill="currentColor" d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/>
          </svg>
          <!-- Pulsing ring -->
          <div class="absolute inset-0 border-2 border-[#d4756a]/50 animate-ping-slow"></div>
        </div>

        <!-- Message -->
        <h2 class="text-[#d4756a] text-lg tracking-wider uppercase mb-3">Resonance Depleted</h2>
        <p class="text-[#8a7d6d] text-sm leading-relaxed mb-6">
          Your energy has fallen too low to remain in this space.
          You will be returned to the grid momentarily.
        </p>

        <!-- Visual divider -->
        <div class="w-24 h-px bg-gradient-to-r from-transparent via-[#d4756a]/40 to-transparent mx-auto mb-6"></div>

        <!-- Advice -->
        <p class="text-[#5a4f42] text-xs tracking-wide">
          Contribute positively to rebuild your resonance.
        </p>
      </div>
    </div>
    """
  end

  attr :user, :map, required: true
  attr :activity, :list, required: true
  attr :is_remembered, :boolean, required: true
  defp user_profile_sidebar(assigns) do
    ~H"""
    <div class="fixed inset-y-0 right-0 w-80 bg-[#0f0d0c] border-l border-[#2a2522] shadow-2xl z-50 flex flex-col animate-slide-in-right">
      <!-- Header -->
      <div class="px-5 py-4 border-b border-[#2a2522] flex items-center justify-between">
        <span class="text-[#5a4f42] text-xs uppercase tracking-wider">Profile</span>
        <button
          phx-click="close_profile"
          class="text-[#5a4f42] hover:text-[#8a7d6d] transition-colors"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
          </svg>
        </button>
      </div>

      <!-- User info -->
      <div class="px-5 py-6 border-b border-[#2a2522]/50">
        <div class="flex items-center gap-4">
          <!-- Large glyph -->
          <div class="flex-shrink-0">
            <svg width="56" height="56" viewBox="-14 -14 28 28">
              <.user_glyph user={@user} />
            </svg>
          </div>
          <div class="flex-1">
            <h3 class="text-[#e8dcc8] text-lg font-medium">
              <%= @user.username || "Anonymous" %>
            </h3>
            <p class="text-[#5a4f42] text-xs uppercase tracking-wider mt-1">
              <%= if @user.username, do: "Registered", else: "Visitor" %>
            </p>
          </div>
        </div>

        <!-- Resonance meter -->
        <div class="mt-5">
          <div class="flex items-center justify-between mb-2">
            <span class="text-[#5a4f42] text-[10px] uppercase tracking-wider">Resonance</span>
            <span class={[
              "text-[10px] uppercase tracking-wider",
              resonance_state_color(Resonance.resonance_state(@user))
            ]}>
              <%= Resonance.resonance_state(@user) %>
            </span>
          </div>
          <div class="h-1.5 bg-[#1a1714] overflow-hidden">
            <div
              class={[
                "h-full transition-all duration-500",
                resonance_bar_color(Resonance.resonance_level(@user))
              ]}
              style={"width: #{Resonance.resonance_percentage(@user)}%"}
            >
            </div>
          </div>
        </div>
      </div>

      <!-- Remember/Forget button -->
      <div class="px-5 py-4 border-b border-[#2a2522]/50">
        <%= if @is_remembered do %>
          <button
            phx-click="forget_user"
            phx-value-id={@user.id}
            class="w-full py-2.5 border border-[#3a3330] text-[#8a7d6d] text-xs uppercase tracking-wider hover:border-[#5a4f42] hover:text-[#a89882] transition-colors"
          >
            Forget
          </button>
        <% else %>
          <button
            phx-click="remember_user"
            phx-value-id={@user.id}
            class="w-full py-2.5 bg-[#c9a962]/20 border border-[#c9a962]/30 text-[#c9a962] text-xs uppercase tracking-wider hover:bg-[#c9a962]/30 transition-colors"
          >
            Remember
          </button>
        <% end %>
      </div>

      <!-- Recent activity -->
      <div class="flex-1 overflow-y-auto">
        <div class="px-5 py-4">
          <h4 class="text-[#5a4f42] text-xs uppercase tracking-wider mb-4">Recent Activity</h4>
          <%= if Enum.empty?(@activity) do %>
            <p class="text-[#3a3330] text-sm italic">No recent activity</p>
          <% else %>
            <div class="space-y-3">
              <%= for visit <- @activity do %>
                <div class="flex items-start gap-3">
                  <div class="w-1.5 h-1.5 rounded-full bg-[#5a4f42] mt-2 flex-shrink-0"></div>
                  <div class="min-w-0">
                    <p class="text-[#c4b8a8] text-sm truncate"><%= visit.node_title %></p>
                    <p class="text-[#3a3330] text-xs"><%= format_visit_time(visit.visited_at) %></p>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp format_visit_time(datetime) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 60 -> "Just now"
      diff < 3600 -> "#{div(diff, 60)} min ago"
      diff < 86400 -> "#{div(diff, 3600)} hours ago"
      true -> Calendar.strftime(datetime, "%b %d")
    end
  end

  attr :user, :map, required: true
  defp user_glyph(assigns) do
    ~H"""
    <%= case @user.glyph_shape do %>
      <% "circle" -> %>
        <circle r="10" fill={@user.glyph_color} />
      <% "triangle" -> %>
        <polygon points="0,-12 10.4,6 -10.4,6" fill={@user.glyph_color} />
      <% "square" -> %>
        <rect x="-8" y="-8" width="16" height="16" fill={@user.glyph_color} />
      <% "diamond" -> %>
        <polygon points="0,-10 10,0 0,10 -10,0" fill={@user.glyph_color} />
      <% "hexagon" -> %>
        <polygon points="8,0 4,6.9 -4,6.9 -8,0 -4,-6.9 4,-6.9" fill={@user.glyph_color} />
      <% "pentagon" -> %>
        <polygon points="0,-9 8.6,-2.8 5.3,7.3 -5.3,7.3 -8.6,-2.8" fill={@user.glyph_color} />
      <% _ -> %>
        <circle r="10" fill={@user.glyph_color || "#888"} />
    <% end %>
    """
  end

  defp typing_text(typing_users) do
    count = length(typing_users)
    cond do
      count == 1 ->
        [{_id, user}] = typing_users
        name = user.username || "someone"
        "#{name} is typing..."
      count == 2 ->
        "2 people are typing..."
      count > 2 ->
        "several people are typing..."
      true ->
        ""
    end
  end

  attr :presence, :map, required: true
  attr :is_self, :boolean, default: false
  attr :is_recognized, :boolean, default: false
  attr :on_click, :string, default: nil
  defp presence_diamond(assigns) do
    # Calculate resonance-based visual properties
    resonance = assigns.presence[:resonance] || 50
    resonance_level = Resonance.resonance_level(%{resonance: resonance})
    {base_opacity, glow_intensity, is_depleted} = resonance_visual_props(resonance_level)

    assigns =
      assigns
      |> assign(:base_opacity, base_opacity)
      |> assign(:glow_intensity, glow_intensity)
      |> assign(:is_depleted, is_depleted)
      |> assign(:resonance_level, resonance_level)

    ~H"""
    <div
      class={"relative group #{if @on_click, do: "cursor-pointer hover:scale-110 transition-all duration-200"}"}
      phx-click={@on_click}
      phx-value-id={@presence.user_id}
    >
      <svg
        width="28"
        height="28"
        viewBox="-14 -14 28 28"
        class={"transition-all duration-300 #{if @presence.typing, do: "animate-pulse scale-110"} #{if @is_depleted, do: "opacity-50"}"}
      >
        <defs>
          <!-- Glow filter for high resonance -->
          <%= if @glow_intensity > 0 do %>
            <filter id={"glow-#{@presence.user_id}"} x="-50%" y="-50%" width="200%" height="200%">
              <feGaussianBlur stdDeviation={@glow_intensity} result="coloredBlur"/>
              <feMerge>
                <feMergeNode in="coloredBlur"/>
                <feMergeNode in="SourceGraphic"/>
              </feMerge>
            </filter>
          <% end %>
        </defs>

        <!-- Radiant aura for high resonance users -->
        <%= if @resonance_level == :radiant && !@is_self do %>
          <polygon
            points="0,-13 13,0 0,13 -13,0"
            fill="none"
            stroke="#c9a962"
            stroke-width="1.5"
            opacity="0.5"
            class="animate-breathe"
          />
        <% end %>

        <!-- Recognition glow ring for remembered users -->
        <%= if @is_recognized && !@is_self do %>
          <polygon
            points="0,-13 13,0 0,13 -13,0"
            fill="none"
            stroke="#c9a962"
            stroke-width="1"
            opacity="0.6"
            class="animate-breathe"
          />
          <polygon
            points="0,-11.5 11.5,0 0,11.5 -11.5,0"
            fill="none"
            stroke="#c9a962"
            stroke-width="0.5"
            opacity="0.3"
          />
        <% end %>

        <!-- Self indicator ring -->
        <%= if @is_self do %>
          <polygon
            points="0,-12 12,0 0,12 -12,0"
            fill="none"
            stroke="#c9a962"
            stroke-width="1.5"
            opacity="0.7"
          />
        <% end %>

        <!-- Depleted warning ring (red pulse) -->
        <%= if @is_depleted && !@is_self do %>
          <polygon
            points="0,-12 12,0 0,12 -12,0"
            fill="none"
            stroke="#d4756a"
            stroke-width="1"
            opacity="0.6"
            class="animate-pulse"
          />
        <% end %>

        <!-- Diamond shape with resonance-based opacity -->
        <g filter={if @glow_intensity > 0, do: "url(#glow-#{@presence.user_id})"}>
          <polygon
            points="0,-9 9,0 0,9 -9,0"
            fill={@presence.glyph_color}
            opacity={if @is_self, do: "1", else: @base_opacity}
          />
        </g>

        <!-- Inner highlight -->
        <polygon
          points="0,-5 5,0 0,5 -5,0"
          fill={@presence.glyph_color}
          opacity={if @is_self, do: "0.5", else: Float.to_string(@base_opacity * 0.4)}
          class={if @is_self || @is_recognized || @resonance_level in [:elevated, :radiant], do: "animate-breathe"}
        />

        <!-- Tiny center spark for recognized or radiant users -->
        <%= if (@is_recognized || @resonance_level == :radiant) && !@is_self do %>
          <circle
            r="1.5"
            fill={if @resonance_level == :radiant, do: "#c9a962", else: "#c9a962"}
            opacity="0.8"
            class="animate-breathe-fast"
          />
        <% end %>
      </svg>

      <!-- Tooltip with username, recognition status, and resonance -->
      <div class="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 px-3 py-1.5 bg-[#0d0b0a] border border-[#2a2522] text-[10px] tracking-wider uppercase whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity duration-200 pointer-events-none shadow-lg">
        <span class={resonance_tooltip_color(@resonance_level, @is_recognized, @is_self)}>
          <%= @presence.username || "Anonymous" %><%= if @is_self, do: " (you)" %>
        </span>
        <%= if @is_recognized && !@is_self do %>
          <span class="ml-2 text-[#5a4f42]">• remembered</span>
        <% end %>
        <%= if @is_depleted && !@is_self do %>
          <span class="ml-2 text-[#d4756a]">• unstable</span>
        <% end %>
      </div>
    </div>
    """
  end

  attr :type, :string, required: true
  defp node_type_badge(assigns) do
    styles = %{
      "discussion" => %{bg: "bg-[#c9a962]/10", border: "border-[#c9a962]/30", text: "text-[#c9a962]"},
      "question" => %{bg: "bg-[#7eb8da]/10", border: "border-[#7eb8da]/30", text: "text-[#7eb8da]"},
      "debate" => %{bg: "bg-[#d4756a]/10", border: "border-[#d4756a]/30", text: "text-[#d4756a]"},
      "quiet" => %{bg: "bg-[#8b9a7d]/10", border: "border-[#8b9a7d]/30", text: "text-[#8b9a7d]"}
    }

    style = Map.get(styles, assigns.type, %{bg: "bg-[#5a4f42]/10", border: "border-[#5a4f42]/30", text: "text-[#5a4f42]"})
    assigns = assign(assigns, :style, style)

    ~H"""
    <span class={"px-3 py-1 text-[10px] uppercase tracking-[0.15em] font-medium border #{@style.bg} #{@style.border} #{@style.text}"}>
      <%= @type %>
    </span>
    """
  end

  attr :message, :map, required: true
  attr :current_user, :map, required: true
  attr :is_recognized, :boolean, default: false
  defp message_bubble(assigns) do
    is_own = assigns.message.user_id == assigns.current_user.id
    assigns = assign(assigns, :is_own, is_own)

    ~H"""
    <div class={"flex gap-4 #{if @is_own, do: "flex-row-reverse"}"}>
      <!-- User glyph with recognition indicator -->
      <div class="flex-shrink-0 relative">
        <svg width="36" height="36" viewBox="-12 -12 24 24">
          <!-- Recognition ring -->
          <%= if @is_recognized && !@is_own do %>
            <circle r="11" fill="none" stroke="#c9a962" stroke-width="1" opacity="0.4" class="animate-breathe" />
          <% end %>
          <.message_glyph user={@message.user} is_own={@is_own} />
        </svg>
      </div>

      <!-- Message content -->
      <div class={[
        "max-w-lg relative group",
        if(@is_own,
          do: "bg-gradient-to-br from-[#c9a962]/15 to-[#c9a962]/5 border border-[#c9a962]/20",
          else: if(@is_recognized,
            do: "bg-[#141210] border border-[#c9a962]/15",
            else: "bg-[#141210] border border-[#1a1714]"
          )
        )
      ]}>
        <!-- Top accent line for recognized users -->
        <%= if @is_recognized && !@is_own do %>
          <div class="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-[#c9a962]/40 via-[#c9a962]/20 to-transparent"></div>
        <% end %>

        <div class="px-4 py-3">
          <!-- Username for non-self messages -->
          <%= if !@is_own && @message.user do %>
            <p class={[
              "text-[10px] uppercase tracking-wider mb-1.5",
              if(@is_recognized, do: "text-[#c9a962]/80", else: "text-[#5a4f42]")
            ]}>
              <%= @message.user.username || "Anonymous" %>
              <%= if @is_recognized do %>
                <span class="text-[#3a3330] ml-1">•</span>
              <% end %>
            </p>
          <% end %>
          <p class="text-[#e8dcc8] text-sm leading-relaxed"><%= @message.content %></p>
          <div class="flex items-center justify-between mt-2">
            <p class="text-[10px] text-[#3a3330] tracking-wide">
              <%= Calendar.strftime(@message.inserted_at, "%H:%M") %>
            </p>
            <!-- Affirm/Dismiss buttons (only for others' messages) -->
            <%= if !@is_own do %>
              <div class="flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
                <button
                  phx-click="affirm_message"
                  phx-value-id={@message.id}
                  class="text-[10px] uppercase tracking-wider text-[#5a4f42] hover:text-[#8b9a7d] transition-colors px-2 py-0.5 border border-transparent hover:border-[#8b9a7d]/30"
                  title="Affirm this message"
                >
                  Affirm
                </button>
                <button
                  phx-click="dismiss_message"
                  phx-value-id={@message.id}
                  class="text-[10px] uppercase tracking-wider text-[#5a4f42] hover:text-[#d4756a] transition-colors px-2 py-0.5 border border-transparent hover:border-[#d4756a]/30"
                  title="Dismiss this message"
                >
                  Dismiss
                </button>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :user, :map, default: nil
  attr :is_own, :boolean, default: false
  defp message_glyph(assigns) do
    user = assigns.user || %{glyph_shape: "circle", glyph_color: "#5a4f42"}
    assigns = assign(assigns, :user, user)

    ~H"""
    <!-- Subtle glow for own messages -->
    <%= if @is_own do %>
      <defs>
        <filter id="glyph-glow" x="-50%" y="-50%" width="200%" height="200%">
          <feGaussianBlur stdDeviation="2" result="coloredBlur"/>
          <feMerge>
            <feMergeNode in="coloredBlur"/>
            <feMergeNode in="SourceGraphic"/>
          </feMerge>
        </filter>
      </defs>
    <% end %>
    <g filter={if @is_own, do: "url(#glyph-glow)"}>
      <%= case @user.glyph_shape do %>
        <% "circle" -> %>
          <circle r="8" fill={@user.glyph_color} opacity={if @is_own, do: "1", else: "0.85"} />
        <% "triangle" -> %>
          <polygon points="0,-9 7.8,4.5 -7.8,4.5" fill={@user.glyph_color} opacity={if @is_own, do: "1", else: "0.85"} />
        <% "square" -> %>
          <rect x="-6" y="-6" width="12" height="12" fill={@user.glyph_color} opacity={if @is_own, do: "1", else: "0.85"} />
        <% "diamond" -> %>
          <polygon points="0,-8 8,0 0,8 -8,0" fill={@user.glyph_color} opacity={if @is_own, do: "1", else: "0.85"} />
        <% "hexagon" -> %>
          <polygon points="6,0 3,5.2 -3,5.2 -6,0 -3,-5.2 3,-5.2" fill={@user.glyph_color} opacity={if @is_own, do: "1", else: "0.85"} />
        <% "pentagon" -> %>
          <polygon points="0,-7 6.7,-2.2 4.1,5.7 -4.1,5.7 -6.7,-2.2" fill={@user.glyph_color} opacity={if @is_own, do: "1", else: "0.85"} />
        <% _ -> %>
          <circle r="8" fill={@user.glyph_color || "#5a4f42"} opacity={if @is_own, do: "1", else: "0.85"} />
      <% end %>
    </g>
    """
  end

  # Resonance helper functions
  defp resonance_state_color("unstable"), do: "text-[#d4756a]"
  defp resonance_state_color("wavering"), do: "text-[#c9a962]/70"
  defp resonance_state_color("steady"), do: "text-[#8a7d6d]"
  defp resonance_state_color("strong"), do: "text-[#8b9a7d]"
  defp resonance_state_color("radiant"), do: "text-[#c9a962]"
  defp resonance_state_color(_), do: "text-[#5a4f42]"

  defp resonance_bar_color(:depleted), do: "bg-[#d4756a]"
  defp resonance_bar_color(:low), do: "bg-[#c9a962]/50"
  defp resonance_bar_color(:normal), do: "bg-[#8a7d6d]"
  defp resonance_bar_color(:elevated), do: "bg-[#8b9a7d]"
  defp resonance_bar_color(:radiant), do: "bg-gradient-to-r from-[#c9a962] to-[#d4b46d]"
  defp resonance_bar_color(_), do: "bg-[#5a4f42]"

  # Returns {base_opacity, glow_intensity, is_depleted} based on resonance level
  defp resonance_visual_props(:depleted), do: {0.4, 0, true}
  defp resonance_visual_props(:low), do: {0.6, 0, false}
  defp resonance_visual_props(:normal), do: {0.85, 0, false}
  defp resonance_visual_props(:elevated), do: {0.95, 1, false}
  defp resonance_visual_props(:radiant), do: {1.0, 2, false}
  defp resonance_visual_props(_), do: {0.85, 0, false}

  defp resonance_tooltip_color(:depleted, _, false), do: "text-[#d4756a]"
  defp resonance_tooltip_color(:radiant, _, false), do: "text-[#c9a962]"
  defp resonance_tooltip_color(_, true, false), do: "text-[#c9a962]"
  defp resonance_tooltip_color(_, _, true), do: "text-[#c9a962]"
  defp resonance_tooltip_color(_, _, _), do: "text-[#8a7d6d]"
end
