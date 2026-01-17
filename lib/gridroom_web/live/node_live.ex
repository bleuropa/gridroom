defmodule GridroomWeb.NodeLive do
  use GridroomWeb, :live_view

  alias Gridroom.{Grid, Accounts, Connections, Resonance}
  alias GridroomWeb.Presence

  @impl true
  def mount(%{"id" => id}, session, socket) do
    case Grid.get_node(id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "This space no longer exists.")
         |> push_navigate(to: ~p"/")}

      node ->
        mount_with_node(node, id, session, socket)
    end
  end

  defp mount_with_node(node, id, session, socket) do
    # Check for logged-in user first, then fall back to anonymous session
    {user, logged_in} =
      case session["user_id"] do
        nil ->
          # Anonymous user - create from session token
          session_id = session["_csrf_token"] || Ecto.UUID.generate()
          {:ok, user} = Accounts.get_or_create_user(session_id)
          {user, false}

        user_id ->
          # Logged-in user
          user = Accounts.get_user(user_id)
          {user, user != nil && user.username != nil}
      end

    # Check if user has enough resonance to enter
    if Resonance.should_kick?(user) do
      {:ok,
       socket
       |> put_flash(:error, "Your resonance is too low to enter this space. Contribute positively elsewhere to rebuild.")
       |> push_navigate(to: ~p"/")}
    else
      mount_node(socket, node, user, id, logged_in)
    end
  end

  defp mount_node(socket, node, user, id, logged_in) do
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

    # Load feedback state for the current user
    cooldown_users = Resonance.users_on_cooldown(user.id)
    feedback_given = Resonance.user_feedback_in_node(user.id, id)

    # Load remembered users for recognition highlighting
    remembered_user_ids =
      user
      |> Connections.list_remembered_users()
      |> Enum.map(& &1.id)
      |> MapSet.new()

    # Load user's buckets for persistent display
    buckets = load_user_buckets(user)

    {:ok,
     socket
     |> assign(:node, node)
     |> assign(:user, user)
     |> assign(:logged_in, logged_in)
     |> assign(:messages, messages)
     |> assign(:present_users, present_users)
     |> assign(:remembered_user_ids, remembered_user_ids)
     |> assign(:cooldown_users, cooldown_users)
     |> assign(:feedback_given, feedback_given)
     |> assign(:buckets, buckets)
     |> assign(:message_form, to_form(%{"content" => ""}))
     |> assign(:page_title, node.title)
     |> assign(:og_title, "#{node.title} - Gridroom")
     |> assign(:og_description, node.description || "Join this conversation at Gridroom")
     |> assign(:show_copied_toast, false)
     |> assign(:typing, false)
     |> assign(:selected_user, nil)
     |> assign(:selected_user_activity, [])
     |> assign(:is_remembered, false)
     |> assign(:kick_warning, nil)
     |> assign(:show_highlights, false)}
  end

  # Load buckets from user's saved IDs, filtering out gone nodes
  defp load_user_buckets(user) do
    user.bucket_ids
    |> Enum.map(&Grid.get_node_with_activity/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(fn node -> node.decay == :gone end)
  end

  defp presence_to_map(presence_list) do
    Enum.reduce(presence_list, %{}, fn {id, %{metas: [meta | _]}}, acc ->
      Map.put(acc, id, meta)
    end)
  end

  @impl true
  def handle_event("send_message", %{"content" => content}, socket) when content != "" do
    # Block anonymous users from chatting
    unless socket.assigns.logged_in do
      {:noreply, socket}
    else
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
        # Update feedback_given map and cooldown_users for immediate UI update
        updated_feedback = Map.put(socket.assigns.feedback_given, message_id, :affirm)
        updated_cooldowns = MapSet.put(socket.assigns.cooldown_users, message.user_id)

        {:noreply,
         socket
         |> assign(:feedback_given, updated_feedback)
         |> assign(:cooldown_users, updated_cooldowns)
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
        # Update feedback_given map and cooldown_users for immediate UI update
        updated_feedback = Map.put(socket.assigns.feedback_given, message_id, :dismiss)
        updated_cooldowns = MapSet.put(socket.assigns.cooldown_users, message.user_id)

        {:noreply,
         socket
         |> assign(:feedback_given, updated_feedback)
         |> assign(:cooldown_users, updated_cooldowns)
         |> push_event("feedback_given", %{message_id: message_id, type: "dismiss"})}

      {:error, :cooldown_active} ->
        {:noreply, socket}

      {:error, :cannot_feedback_self} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("show_highlights", _params, socket) do
    {:noreply, assign(socket, :show_highlights, true)}
  end

  @impl true
  def handle_event("hide_highlights", _params, socket) do
    {:noreply, assign(socket, :show_highlights, false)}
  end

  @impl true
  def handle_event("navigate_to_bucket", %{"index" => index}, socket) do
    case Enum.at(socket.assigns.buckets, index) do
      nil -> {:noreply, socket}
      bucket -> {:noreply, push_navigate(socket, to: ~p"/node/#{bucket.id}")}
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
    <div class="h-screen lumon-terminal flex flex-col room-entrance relative overflow-hidden" phx-hook="NodeKeys" id="room-container">
      <!-- Lumon CRT atmosphere layers -->
      <div class="pointer-events-none fixed inset-0 lumon-vignette"></div>
      <div class="pointer-events-none fixed inset-0 lumon-scanlines"></div>
      <div class="pointer-events-none fixed inset-0 lumon-glow"></div>

      <!-- Header - Severance terminal style -->
      <header class="relative z-10 border-b border-[#1a1714]/50 bg-[#0a0908]/80 backdrop-blur-sm">
        <div class="px-6 py-4 flex items-center gap-4">
          <a href={"/?from=#{@node.id}"} class="text-[#4a4540] hover:text-[#8a8278] transition-colors duration-200">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M10 19l-7-7m0 0l7-7m-7 7h18"/>
            </svg>
          </a>
          <div class="flex-1 min-w-0">
            <h1 class="text-base font-mono font-normal tracking-wide text-[#e8e0d4] truncate"><%= @node.title %></h1>
            <%= if @node.description do %>
              <p class="text-xs font-mono text-[#7a7268] mt-1 truncate"><%= @node.description %></p>
            <% end %>
            <!-- Sources (for trend-generated nodes) -->
            <%= if @node.sources && length(@node.sources) > 0 do %>
              <.sources_display sources={@node.sources} />
            <% end %>
          </div>
          <button
            id="share-button"
            phx-click="copy_share_url"
            phx-hook="CopyToClipboard"
            data-copy-text={url(~p"/node/#{@node.id}")}
            class="text-[#4a4540] hover:text-[#8a8278] text-[10px] font-mono uppercase tracking-widest transition-colors duration-200"
          >
            share
          </button>
        </div>
      </header>

      <!-- Copied toast -->
      <%= if @show_copied_toast do %>
        <div class="fixed top-20 left-1/2 -translate-x-1/2 z-50 animate-fade-in">
          <div class="bg-[#0a0908] border border-[#2a2520]/50 px-4 py-2 text-[10px] font-mono tracking-widest uppercase text-[#8a8278]">
            copied
          </div>
        </div>
      <% end %>

      <!-- Messages area -->
      <div
        id="messages"
        class="relative z-10 flex-1 overflow-y-auto px-6 py-4 min-h-0"
        phx-hook="ScrollToBottom"
      >
        <%= if Enum.empty?(@messages) do %>
          <div class="flex flex-col items-center justify-center h-full text-center">
            <p class="text-[#4a4540] text-xs font-mono tracking-[0.2em] uppercase">awaiting input</p>
          </div>
        <% else %>
          <div class="space-y-3">
            <%= for message <- @messages do %>
              <.message_bubble
                message={message}
                current_user={@user}
                is_recognized={MapSet.member?(@remembered_user_ids, message.user_id)}
                on_cooldown={MapSet.member?(@cooldown_users, message.user_id)}
                feedback_type={Map.get(@feedback_given, message.id)}
              />
            <% end %>
          </div>
        <% end %>
      </div>

      <!-- Bottom section: presence row + input -->
      <div class="relative z-10 border-t border-[#1a1714]/50 bg-[#0a0908]/90">
        <!-- Presence row -->
        <div class="px-6 py-3 border-b border-[#1a1714]/30">
          <div class="flex items-center gap-2">
            <span class="text-[#3a3530] text-[9px] font-mono uppercase tracking-widest">present</span>
            <div class="flex items-center gap-2 ml-2">
              <%= for {_id, presence} <- @present_users do %>
                <.presence_diamond
                  presence={presence}
                  is_self={presence.user_id == @user.id}
                  is_recognized={MapSet.member?(@remembered_user_ids, presence.user_id)}
                  shared_bucket_indices={shared_bucket_indices(presence.user_id, @buckets, @node.id)}
                  on_click={if presence.user_id != @user.id, do: "select_user"}
                />
              <% end %>
            </div>
            <!-- Typing indicator -->
            <% typing_users = Enum.filter(@present_users, fn {id, p} -> p.typing && id != @user.id end) %>
            <%= if length(typing_users) > 0 do %>
              <span class="text-[#6a6258] text-[10px] font-mono tracking-wide animate-pulse">
                <%= typing_text(typing_users) %>
              </span>
            <% end %>
            <!-- Bucket indicators -->
            <%= if length(@buckets) > 0 do %>
              <div class="flex items-center gap-2 ml-auto">
                <span class="text-[9px] font-mono text-[#3a3530] uppercase tracking-widest">buckets</span>
                <%= for {bucket, index} <- Enum.with_index(@buckets) do %>
                  <a
                    href={~p"/node/#{bucket.id}"}
                    class={[
                      "w-6 h-6 rounded-full border flex items-center justify-center text-[9px] font-mono transition-all duration-200",
                      bucket_color_classes(index, bucket.id == @node.id)
                    ]}
                    title={bucket.title}
                  >
                    <%= index + 1 %>
                  </a>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>

        <!-- Input area - terminal style (or login prompt for anonymous) -->
        <div class="px-6 py-4">
          <%= if @logged_in do %>
            <.form for={@message_form} phx-submit="send_message" class="flex gap-3">
              <div class="flex-1 relative">
                <span class="absolute left-3 top-1/2 -translate-y-1/2 text-[#4a4540] text-sm font-mono">></span>
                <input
                  type="text"
                  name="content"
                  id="message-input"
                  phx-hook="TypingIndicator"
                  value={@message_form[:content].value}
                  placeholder=""
                  class="w-full bg-transparent border border-[#2a2520]/50 pl-7 pr-4 py-3 text-[#e8e0d4] font-mono text-sm placeholder-[#3a3530] focus:outline-none focus:border-[#4a4540] transition-colors duration-200"
                  autocomplete="off"
                />
              </div>
              <button
                type="submit"
                class="px-6 py-3 border border-[#4a4540]/50 text-[#8a8278] text-[10px] font-mono uppercase tracking-widest hover:border-[#6a6258] hover:text-[#a8a298] transition-colors duration-200"
              >
                send
              </button>
            </.form>
          <% else %>
            <!-- Login prompt for anonymous users -->
            <div class="flex items-center justify-between py-2 px-4 border border-[#2a2520]/50 bg-[#1a1714]/30">
              <p class="text-[#6a6258] text-xs font-mono">
                <span class="text-[#4a4540]">></span> Induction required to participate
              </p>
              <div class="flex items-center gap-4">
                <.link navigate={~p"/login"} class="text-[#8b9a7d] text-[10px] font-mono uppercase tracking-wider hover:text-[#a8b89d]">
                  Clock in
                </.link>
                <.link navigate={~p"/register"} class="text-[#c9a962] text-[10px] font-mono uppercase tracking-wider hover:text-[#d9b972]">
                  Request access
                </.link>
              </div>
            </div>
          <% end %>
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

      <!-- Highlights overlay (space held) -->
      <%= if @show_highlights do %>
        <.highlights_overlay messages={highlighted_messages(@messages)} />
      <% end %>

      <!-- Kick warning overlay -->
      <%= if @kick_warning do %>
        <.kick_warning_overlay warning={@kick_warning} />
      <% end %>
    </div>
    """
  end

  # Get top 5 most affirmed messages for highlights
  defp highlighted_messages(messages) do
    messages
    |> Enum.filter(fn m -> (m.affirm_count || 0) > 0 end)
    |> Enum.sort_by(fn m -> m.affirm_count || 0 end, :desc)
    |> Enum.take(5)
  end

  defp highlights_overlay(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-black/85 backdrop-blur-sm z-[90] flex items-center justify-center animate-fade-in">
      <div class="max-w-2xl w-full mx-6">
        <!-- Header -->
        <div class="text-center mb-8">
          <h2 class="text-[#e8e0d4] text-lg font-mono tracking-widest uppercase mb-2">Highlights</h2>
          <p class="text-[#5a5248] text-xs font-mono tracking-wide">Most affirmed contributions</p>
        </div>

        <%= if Enum.empty?(@messages) do %>
          <div class="text-center py-12">
            <p class="text-[#4a4540] text-sm font-mono">No affirmed messages yet</p>
          </div>
        <% else %>
          <div class="space-y-4">
            <%= for {message, rank} <- Enum.with_index(@messages, 1) do %>
              <div class="bg-[#0d0b0a]/80 border border-[#c9a962]/20 p-4">
                <div class="flex items-start gap-4">
                  <!-- Rank -->
                  <div class="w-8 h-8 rounded-full border border-[#c9a962]/40 flex items-center justify-center flex-shrink-0">
                    <span class="text-[#c9a962] text-sm font-mono"><%= rank %></span>
                  </div>
                  <!-- Content -->
                  <div class="flex-1 min-w-0">
                    <p class="text-[#c8c0b4] text-sm font-mono leading-relaxed mb-2"><%= message.content %></p>
                    <div class="flex items-center gap-4">
                      <span class="text-[#6a6258] text-[10px] font-mono">
                        <%= message.user && message.user.username || "anon" %>
                      </span>
                      <span class="text-[#8b9a7d] text-[10px] font-mono uppercase tracking-wider">
                        <%= message.affirm_count %> affirmation<%= if message.affirm_count != 1, do: "s" %>
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>

        <!-- Hint -->
        <p class="text-center text-[#3a3530] text-[10px] font-mono tracking-wider uppercase mt-8">
          release space to close
        </p>
      </div>
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
  attr :shared_bucket_indices, :list, default: []
  attr :on_click, :string, default: nil
  defp presence_diamond(assigns) do
    ~H"""
    <div
      class={"relative group #{if @on_click, do: "cursor-pointer"}"}
      phx-click={@on_click}
      phx-value-id={@presence.user_id}
    >
      <!-- Shared bucket rings -->
      <%= for idx <- @shared_bucket_indices do %>
        <div
          class="absolute inset-0 rounded-full animate-pulse"
          style={"
            width: #{12 + idx * 6}px;
            height: #{12 + idx * 6}px;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            border: 1px solid #{bucket_ring_color(idx)};
            opacity: 0.6;
          "}
        ></div>
      <% end %>
      <div class={[
        "w-2 h-2 rounded-full transition-all duration-200 relative z-10",
        cond do
          @is_self -> "bg-[#8b9a7d]"
          @is_recognized -> "bg-[#c9a962]"
          @presence.typing -> "bg-[#6a6258] animate-pulse"
          true -> "bg-[#4a4540]"
        end,
        if(@on_click, do: "hover:scale-125")
      ]}></div>
      <!-- Tooltip -->
      <div class="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 px-2 py-1 bg-[#0a0908] border border-[#2a2520]/50 text-[9px] font-mono tracking-wider whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity duration-200 pointer-events-none z-20">
        <span class={if @is_self, do: "text-[#8b9a7d]", else: "text-[#8a8278]"}>
          <%= @presence.username || "anon" %><%= if @is_self, do: " (you)" %>
        </span>
        <%= if length(@shared_bucket_indices) > 0 do %>
          <span class="text-[#5a5248] ml-1">
            (in <%= length(@shared_bucket_indices) %> shared bucket<%= if length(@shared_bucket_indices) > 1, do: "s" %>)
          </span>
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
  attr :on_cooldown, :boolean, default: false
  attr :feedback_type, :atom, default: nil
  defp message_bubble(assigns) do
    is_own = assigns.message.user_id == assigns.current_user.id
    can_give_feedback = !is_own && !assigns.on_cooldown && is_nil(assigns.feedback_type)
    assigns = assigns
      |> assign(:is_own, is_own)
      |> assign(:can_give_feedback, can_give_feedback)

    ~H"""
    <div class="group" data-message-id={@message.id}>
      <div class="flex items-start gap-3">
        <!-- Timestamp -->
        <span class="text-[9px] font-mono text-[#3a3530] w-10 pt-0.5 flex-shrink-0">
          <%= Calendar.strftime(@message.inserted_at, "%H:%M") %>
        </span>
        <!-- Username -->
        <span class={[
          "text-xs font-mono w-24 truncate flex-shrink-0 pt-0.5",
          cond do
            @is_own -> "text-[#8b9a7d]"
            @is_recognized -> "text-[#c9a962]"
            true -> "text-[#6a6258]"
          end
        ]}>
          <%= if @is_own do %>you<% else %><%= @message.user && @message.user.username || "anon" %><% end %>
        </span>
        <!-- Message content -->
        <p class="flex-1 text-sm font-mono text-[#c8c0b4] leading-relaxed"><%= @message.content %></p>
        <!-- Feedback buttons (Lumon terminology: affirm/dismiss) -->
        <%= if @can_give_feedback do %>
          <div class="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
            <button
              phx-click="affirm_message"
              phx-value-id={@message.id}
              class="px-2 py-0.5 text-[8px] font-mono uppercase tracking-widest text-[#4a4540] hover:text-[#8b9a7d] hover:bg-[#8b9a7d]/10 border border-transparent hover:border-[#8b9a7d]/30 transition-all duration-200"
              title="Affirm this contribution"
            >
              affirm
            </button>
            <button
              phx-click="dismiss_message"
              phx-value-id={@message.id}
              class="px-2 py-0.5 text-[8px] font-mono uppercase tracking-widest text-[#4a4540] hover:text-[#d4756a] hover:bg-[#d4756a]/10 border border-transparent hover:border-[#d4756a]/30 transition-all duration-200"
              title="Dismiss this contribution"
            >
              dismiss
            </button>
          </div>
        <% else %>
          <%= if @feedback_type do %>
            <span class={[
              "text-[8px] font-mono uppercase tracking-widest",
              if(@feedback_type == :affirm, do: "text-[#8b9a7d]", else: "text-[#d4756a]")
            ]}>
              <%= if @feedback_type == :affirm, do: "affirmed", else: "dismissed" %>
            </span>
          <% end %>
        <% end %>
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

  # Bucket color system - 6 distinct colors for up to 6 buckets
  # Each entry has: active classes, inactive classes, and ring color for presence
  @bucket_colors [
    %{active: "border-[#c9a962] bg-[#c9a962]/20 text-[#c9a962]",
      inactive: "border-[#3a3530] text-[#4a4540] hover:border-[#c9a962] hover:text-[#c9a962]",
      ring: "#c9a962"},      # Gold
    %{active: "border-[#7eb8da] bg-[#7eb8da]/20 text-[#7eb8da]",
      inactive: "border-[#3a3530] text-[#4a4540] hover:border-[#7eb8da] hover:text-[#7eb8da]",
      ring: "#7eb8da"},      # Blue
    %{active: "border-[#8b9a7d] bg-[#8b9a7d]/20 text-[#8b9a7d]",
      inactive: "border-[#3a3530] text-[#4a4540] hover:border-[#8b9a7d] hover:text-[#8b9a7d]",
      ring: "#8b9a7d"},      # Sage
    %{active: "border-[#d4756a] bg-[#d4756a]/20 text-[#d4756a]",
      inactive: "border-[#3a3530] text-[#4a4540] hover:border-[#d4756a] hover:text-[#d4756a]",
      ring: "#d4756a"},      # Coral
    %{active: "border-[#b49ddb] bg-[#b49ddb]/20 text-[#b49ddb]",
      inactive: "border-[#3a3530] text-[#4a4540] hover:border-[#b49ddb] hover:text-[#b49ddb]",
      ring: "#b49ddb"},      # Lavender
    %{active: "border-[#e8c094] bg-[#e8c094]/20 text-[#e8c094]",
      inactive: "border-[#3a3530] text-[#4a4540] hover:border-[#e8c094] hover:text-[#e8c094]",
      ring: "#e8c094"}       # Peach
  ]

  defp bucket_color_classes(index, is_current) do
    color = Enum.at(@bucket_colors, index, List.first(@bucket_colors))
    if is_current, do: color.active, else: color.inactive
  end

  defp bucket_ring_color(index) do
    color = Enum.at(@bucket_colors, index, List.first(@bucket_colors))
    color.ring
  end

  # Find which bucket indices a user shares with the current user (excluding current node)
  defp shared_bucket_indices(user_id, buckets, current_node_id) do
    # We need to check Presence data for other buckets to see if user is there
    # For now, we'll check if the user's ID appears in presence of other bucket nodes
    # This requires querying presence for each bucket - return empty for now,
    # the full implementation needs presence subscription for other nodes
    buckets
    |> Enum.with_index()
    |> Enum.filter(fn {bucket, _idx} -> bucket.id != current_node_id end)
    |> Enum.filter(fn {bucket, _idx} ->
      # Check if user is present in this bucket's node
      presence_list = Presence.list_users_in_node(bucket.id)
      Enum.any?(presence_list, fn {id, _} -> id == user_id end)
    end)
    |> Enum.map(fn {_bucket, idx} -> idx end)
  end

  # Highlight card for top affirmed messages
  attr :message, :map, required: true
  defp highlight_card(assigns) do
    ~H"""
    <div class="flex-shrink-0 w-72 bg-[#141210] border border-[#c9a962]/20 p-3 hover:border-[#c9a962]/40 transition-colors">
      <!-- Header with user and affirm count -->
      <div class="flex items-center justify-between mb-2">
        <div class="flex items-center gap-2">
          <svg width="16" height="16" viewBox="-8 -8 16 16">
            <%= case @message.user && @message.user.glyph_shape do %>
              <% "circle" -> %>
                <circle r="5" fill={@message.user && @message.user.glyph_color || "#5a4f42"} />
              <% "triangle" -> %>
                <polygon points="0,-6 5.2,3 -5.2,3" fill={@message.user && @message.user.glyph_color || "#5a4f42"} />
              <% "square" -> %>
                <rect x="-4" y="-4" width="8" height="8" fill={@message.user && @message.user.glyph_color || "#5a4f42"} />
              <% "diamond" -> %>
                <polygon points="0,-5 5,0 0,5 -5,0" fill={@message.user && @message.user.glyph_color || "#5a4f42"} />
              <% "hexagon" -> %>
                <polygon points="4,0 2,3.5 -2,3.5 -4,0 -2,-3.5 2,-3.5" fill={@message.user && @message.user.glyph_color || "#5a4f42"} />
              <% "pentagon" -> %>
                <polygon points="0,-5 4.8,-1.5 3,4 -3,4 -4.8,-1.5" fill={@message.user && @message.user.glyph_color || "#5a4f42"} />
              <% _ -> %>
                <circle r="5" fill={@message.user && @message.user.glyph_color || "#5a4f42"} />
            <% end %>
          </svg>
          <span class="text-[10px] uppercase tracking-wider text-[#5a4f42]">
            <%= (@message.user && @message.user.username) || "Anonymous" %>
          </span>
        </div>
        <div class="flex items-center gap-1 text-[#c9a962]">
          <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/>
          </svg>
          <span class="text-[10px] uppercase tracking-wider"><%= @message.affirm_count %></span>
        </div>
      </div>
      <!-- Message content (truncated) -->
      <p class="text-[#c4b8a8] text-xs leading-relaxed line-clamp-2">
        <%= @message.content %>
      </p>
    </div>
    """
  end

  # Sources display component for trend-generated nodes
  attr :sources, :list, required: true
  defp sources_display(assigns) do
    ~H"""
    <div class="mt-3">
      <div class="flex items-center gap-2 mb-2">
        <span class="text-[#3a3330] text-[9px] uppercase tracking-[0.15em]">Sources</span>
        <div class="flex-1 h-px bg-gradient-to-r from-[#2a2522] to-transparent"></div>
      </div>
      <div class="space-y-1.5">
        <%= for {source, idx} <- Enum.with_index(@sources) do %>
          <a
            href={source["url"]}
            target="_blank"
            rel="noopener noreferrer"
            class="group flex items-start gap-2 px-3 py-2 bg-[#0d0b0a]/50 border border-[#1a1714] hover:border-[#c9a962]/20 hover:bg-[#141210] transition-all duration-300"
          >
            <!-- Source number and icon -->
            <div class="flex items-center gap-1.5 flex-shrink-0 mt-0.5">
              <%= if source["type"] == "x" do %>
                <svg class="w-3 h-3 text-[#4a4038] group-hover:text-[#c9a962] transition-colors" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>
                </svg>
              <% else %>
                <svg class="w-3 h-3 text-[#4a4038] group-hover:text-[#c9a962] transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M13.19 8.688a4.5 4.5 0 011.242 7.244l-4.5 4.5a4.5 4.5 0 01-6.364-6.364l1.757-1.757m13.35-.622l1.757-1.757a4.5 4.5 0 00-6.364-6.364l-4.5 4.5a4.5 4.5 0 001.242 7.244"/>
                </svg>
              <% end %>
              <span class="text-[9px] uppercase tracking-wider text-[#3a3330] group-hover:text-[#5a4f42] transition-colors">
                <%= idx + 1 %>
              </span>
            </div>
            <!-- Summary text -->
            <div class="flex-1 min-w-0">
              <%= if source["summary"] && source["summary"] != "" do %>
                <p class="text-[11px] text-[#8a7d6d] group-hover:text-[#a89882] transition-colors leading-relaxed">
                  <%= source["summary"] %>
                </p>
              <% else %>
                <p class="text-[10px] text-[#4a4038] italic">
                  View source
                </p>
              <% end %>
            </div>
            <!-- External link indicator -->
            <svg class="w-3 h-3 text-[#3a3330] group-hover:text-[#c9a962] transition-colors flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 19.5l15-15m0 0H8.25m11.25 0v11.25"/>
            </svg>
          </a>
        <% end %>
      </div>
    </div>
    """
  end
end
