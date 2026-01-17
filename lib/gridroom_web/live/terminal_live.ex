defmodule GridroomWeb.TerminalLive do
  @moduledoc """
  Lumon-inspired terminal interface for discovering discussions.

  Discussions appear as scrolling text streams with activity-based sizing.
  Users "bucket" discussions they want to follow and toggle between views.
  """

  use GridroomWeb, :live_view

  alias Gridroom.{Grid, Accounts}
  alias GridroomWeb.Presence

  @impl true
  def mount(_params, session, socket) do
    # Check for logged-in user first, then fall back to anonymous session
    user =
      case session["user_id"] do
        nil ->
          session_id = session["_csrf_token"] || Ecto.UUID.generate()
          {:ok, user} = Accounts.get_or_create_user(session_id)
          user

        user_id ->
          Accounts.get_user(user_id)
      end

    # Subscribe to presence, node updates, and personal resonance changes
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Gridroom.PubSub, "grid:presence")
      Phoenix.PubSub.subscribe(Gridroom.PubSub, "grid:nodes")
      Phoenix.PubSub.subscribe(Gridroom.PubSub, "user:#{user.id}:resonance")
      Presence.track_user(self(), user)
    end

    # Load nodes with activity
    nodes = Grid.list_nodes_with_activity()

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:logged_in, user && user.username != nil)
     |> assign(:nodes, nodes)
     |> assign(:buckets, [nil, nil, nil, nil, nil, nil])  # 6 bucket slots
     |> assign(:active_bucket, nil)  # Index of currently viewing bucket
     |> assign(:view_mode, :stream)  # :stream or :discussion
     |> assign(:stream_paused, false)
     |> assign(:page_title, "Gridroom")
     |> assign(:show_create_node, false)
     |> assign(:resonance_toasts, [])}
  end

  @impl true
  def handle_event("bucket_node", %{"id" => node_id}, socket) do
    node = Enum.find(socket.assigns.nodes, &(&1.id == node_id))

    if node do
      buckets = socket.assigns.buckets

      # Find first empty slot
      empty_index = Enum.find_index(buckets, &is_nil/1)

      # Check if already bucketed
      already_bucketed = Enum.any?(buckets, fn b -> b && b.id == node_id end)

      cond do
        already_bucketed ->
          # Already in bucket, activate it
          index = Enum.find_index(buckets, fn b -> b && b.id == node_id end)
          {:noreply, socket |> assign(:active_bucket, index) |> assign(:view_mode, :discussion)}

        empty_index ->
          # Add to first empty slot
          new_buckets = List.replace_at(buckets, empty_index, node)
          {:noreply, assign(socket, :buckets, new_buckets)}

        true ->
          # All slots full
          {:noreply, put_flash(socket, :error, "All buckets full. Remove one first.")}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("remove_bucket", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    buckets = socket.assigns.buckets
    new_buckets = List.replace_at(buckets, index, nil)

    # If removing active bucket, go back to stream
    socket = if socket.assigns.active_bucket == index do
      socket |> assign(:active_bucket, nil) |> assign(:view_mode, :stream)
    else
      socket
    end

    {:noreply, assign(socket, :buckets, new_buckets)}
  end

  @impl true
  def handle_event("activate_bucket", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    bucket = Enum.at(socket.assigns.buckets, index)

    if bucket do
      {:noreply, socket |> assign(:active_bucket, index) |> assign(:view_mode, :discussion)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle_view", _params, socket) do
    case socket.assigns.view_mode do
      :stream ->
        # If there's an active bucket, show it
        if socket.assigns.active_bucket do
          {:noreply, assign(socket, :view_mode, :discussion)}
        else
          {:noreply, socket}
        end

      :discussion ->
        {:noreply, assign(socket, :view_mode, :stream)}
    end
  end

  @impl true
  def handle_event("keydown", %{"key" => key}, socket) do
    cond do
      # Number keys 1-6 activate buckets
      key in ~w(1 2 3 4 5 6) ->
        index = String.to_integer(key) - 1
        bucket = Enum.at(socket.assigns.buckets, index)

        if bucket do
          {:noreply, socket |> assign(:active_bucket, index) |> assign(:view_mode, :discussion)}
        else
          {:noreply, socket}
        end

      # Spacebar toggles view
      key == " " ->
        handle_event("toggle_view", %{}, socket)

      # Escape goes to stream
      key == "Escape" ->
        {:noreply, assign(socket, :view_mode, :stream)}

      # N opens create node (if logged in)
      key == "n" and socket.assigns.logged_in ->
        {:noreply, assign(socket, :show_create_node, true)}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("pause_stream", _params, socket) do
    {:noreply, assign(socket, :stream_paused, true)}
  end

  @impl true
  def handle_event("resume_stream", _params, socket) do
    {:noreply, assign(socket, :stream_paused, false)}
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
    {:noreply, assign(socket, :show_create_node, false)}
  end

  @impl true
  def handle_event("create_node", %{"title" => title, "description" => description, "node_type" => node_type}, socket) do
    user = socket.assigns.user

    attrs = %{
      title: String.trim(title),
      description: String.trim(description),
      position_x: :rand.uniform() * 400 - 200,  # Random position for terminal view
      position_y: :rand.uniform() * 400 - 200,
      node_type: node_type,
      created_by_id: user.id
    }

    case Grid.create_node(attrs) do
      {:ok, node} ->
        # Auto-bucket the new node
        buckets = socket.assigns.buckets
        empty_index = Enum.find_index(buckets, &is_nil/1) || 0
        new_buckets = List.replace_at(buckets, empty_index, node)

        {:noreply,
         socket
         |> assign(:show_create_node, false)
         |> assign(:buckets, new_buckets)
         |> assign(:active_bucket, empty_index)
         |> assign(:view_mode, :discussion)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not create discussion")}
    end
  end

  @impl true
  def handle_event("enter_discussion", %{"id" => node_id}, socket) do
    # Navigate to the full discussion view
    {:noreply, push_navigate(socket, to: "/node/#{node_id}")}
  end

  # PubSub handlers
  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: _diff}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:node_created, node}, socket) do
    nodes = [node | socket.assigns.nodes]
    {:noreply, assign(socket, :nodes, nodes)}
  end

  @impl true
  def handle_info({:resonance_changed, %{user: updated_user, amount: amount, reason: reason}}, socket) do
    toast = %{
      id: System.unique_integer([:positive]),
      amount: amount,
      reason: reason,
      timestamp: System.system_time(:second)
    }

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
  def render(assigns) do
    ~H"""
    <div
      id="terminal-container"
      class="fixed inset-0 bg-[#0a0908] overflow-hidden flex flex-col terminal-glow"
      phx-hook="TerminalKeys"
      phx-window-keydown="keydown"
    >
      <!-- Scanline overlay -->
      <div class="pointer-events-none fixed inset-0 scanlines opacity-[0.03]"></div>

      <!-- Header bar -->
      <header class="flex-none h-12 border-b border-[#1a1714] flex items-center justify-between px-6">
        <div class="flex items-center gap-6">
          <h1 class="text-[#3a3530] text-xs tracking-[0.3em] uppercase font-mono">Gridroom Terminal</h1>
          <div class="flex items-center gap-2">
            <div class="w-1.5 h-1.5 rounded-full bg-[#8b9a7d] animate-pulse"></div>
            <span class="text-[#5a4f42] text-[10px] font-mono"><%= length(@nodes) %> discussions</span>
          </div>
        </div>

        <div class="flex items-center gap-4">
          <%= if @logged_in do %>
            <span class="text-[#5a4f42] text-xs font-mono"><%= @user.username %></span>
            <.link href={~p"/logout"} method="delete" class="text-[#3a3530] hover:text-[#5a4f42] text-xs font-mono">
              logout
            </.link>
          <% else %>
            <.link navigate={~p"/login"} class="text-[#8b9a7d] hover:text-[#a0b090] text-xs font-mono">
              sign in
            </.link>
          <% end %>
        </div>
      </header>

      <!-- Main content area -->
      <main class="flex-1 relative overflow-hidden">
        <!-- Stream view -->
        <div class={[
          "absolute inset-0 transition-opacity duration-300",
          if(@view_mode == :stream, do: "opacity-100", else: "opacity-0 pointer-events-none")
        ]}>
          <.stream_view nodes={@nodes} paused={@stream_paused} />
        </div>

        <!-- Discussion view (overlay) -->
        <%= if @view_mode == :discussion && @active_bucket != nil do %>
          <% active_node = Enum.at(@buckets, @active_bucket) %>
          <%= if active_node do %>
            <.discussion_overlay node={active_node} />
          <% end %>
        <% end %>

        <!-- Create node modal -->
        <%= if @show_create_node do %>
          <.create_node_modal />
        <% end %>
      </main>

      <!-- Bucket bar -->
      <footer class="flex-none h-16 border-t border-[#1a1714] bg-[#0d0b0a]/80 backdrop-blur">
        <div class="h-full flex items-center justify-center gap-3 px-6">
          <%= for {bucket, index} <- Enum.with_index(@buckets) do %>
            <.bucket_slot
              bucket={bucket}
              index={index}
              active={@active_bucket == index && @view_mode == :discussion}
            />
          <% end %>

          <!-- Spacer -->
          <div class="w-px h-8 bg-[#1a1714] mx-4"></div>

          <!-- Controls hint -->
          <div class="text-[#3a3530] text-[10px] font-mono">
            <span class="text-[#5a4f42]">1-6</span> select ·
            <span class="text-[#5a4f42]">space</span> toggle ·
            <span class="text-[#5a4f42]">esc</span> stream
            <%= if @logged_in do %>
              · <span class="text-[#5a4f42]">n</span> new
            <% end %>
          </div>
        </div>
      </footer>

      <!-- Resonance toasts -->
      <div class="fixed top-16 right-6 flex flex-col gap-2 z-50">
        <%= for toast <- @resonance_toasts do %>
          <.resonance_toast toast={toast} />
        <% end %>
      </div>
    </div>
    """
  end

  # Stream view component - scrolling discussions
  defp stream_view(assigns) do
    # Sort nodes by activity (most active first for visual prominence)
    sorted_nodes = Enum.sort_by(assigns.nodes, fn node ->
      case node.activity.level do
        :buzzing -> 0
        :active -> 1
        :quiet -> 2
        :dormant -> 3
      end
    end)

    assigns = assign(assigns, :sorted_nodes, sorted_nodes)

    ~H"""
    <div
      class="h-full overflow-hidden relative"
      phx-mouseenter="pause_stream"
      phx-mouseleave="resume_stream"
    >
      <!-- Gradient fade at top and bottom -->
      <div class="absolute top-0 left-0 right-0 h-24 bg-gradient-to-b from-[#0a0908] to-transparent z-10 pointer-events-none"></div>
      <div class="absolute bottom-0 left-0 right-0 h-24 bg-gradient-to-t from-[#0a0908] to-transparent z-10 pointer-events-none"></div>

      <!-- Scrolling content -->
      <div class={[
        "h-full flex flex-col justify-center items-center gap-8 py-32 overflow-y-auto scrollbar-hide",
        if(@paused, do: "", else: "animate-stream-scroll")
      ]}>
        <%= for {node, index} <- Enum.with_index(@sorted_nodes) do %>
          <.stream_item node={node} index={index} />
        <% end %>

        <%= if Enum.empty?(@sorted_nodes) do %>
          <div class="text-[#3a3530] text-sm font-mono">
            No discussions yet. Be the first to create one.
          </div>
        <% end %>
      </div>

      <!-- Pause indicator -->
      <%= if @paused do %>
        <div class="absolute top-4 right-4 flex items-center gap-2 text-[#5a4f42] text-xs font-mono">
          <div class="w-2 h-2 bg-[#c9a962]"></div>
          paused
        </div>
      <% end %>
    </div>
    """
  end

  # Individual stream item
  defp stream_item(assigns) do
    # Calculate font size based on activity
    {font_size, opacity} = case assigns.node.activity.level do
      :buzzing -> {"text-2xl", "opacity-100"}
      :active -> {"text-xl", "opacity-90"}
      :quiet -> {"text-base", "opacity-70"}
      :dormant -> {"text-sm", "opacity-50"}
    end

    # Random-ish horizontal offset for organic feel
    offset = rem(assigns.index * 73, 40) - 20

    assigns = assigns
      |> assign(:font_size, font_size)
      |> assign(:opacity, opacity)
      |> assign(:offset, offset)

    ~H"""
    <button
      phx-click="bucket_node"
      phx-value-id={@node.id}
      class={[
        "group cursor-pointer transition-all duration-300 hover:scale-105 text-left max-w-2xl",
        @font_size,
        @opacity
      ]}
      style={"transform: translateX(#{@offset}px);"}
    >
      <div class="flex flex-col gap-1">
        <!-- Title -->
        <span class={[
          "font-mono tracking-wide transition-colors",
          activity_color(@node.activity.level),
          "group-hover:text-[#e8e0d5]"
        ]}>
          <%= @node.title %>
        </span>

        <!-- Description (smaller) -->
        <%= if @node.description && @node.description != "" do %>
          <span class="text-[#3a3530] text-xs font-mono truncate max-w-md group-hover:text-[#5a4f42] transition-colors">
            "<%= truncate(@node.description, 60) %>"
          </span>
        <% end %>

        <!-- Activity indicator -->
        <div class="flex items-center gap-2 mt-1">
          <div class={["w-1.5 h-1.5 rounded-full", activity_dot_class(@node.activity.level)]}></div>
          <span class="text-[#3a3530] text-[10px] font-mono uppercase tracking-wider">
            <%= @node.activity.level %>
            <%= if @node.activity.count > 0 do %>
              · <%= @node.activity.count %> msg/hr
            <% end %>
          </span>
        </div>
      </div>
    </button>
    """
  end

  # Bucket slot component
  defp bucket_slot(assigns) do
    ~H"""
    <div class={[
      "w-32 h-10 border font-mono text-xs flex items-center justify-center gap-2 transition-all cursor-pointer",
      if(@bucket,
        do: if(@active,
          do: "border-[#8b9a7d] bg-[#8b9a7d]/10 text-[#8b9a7d]",
          else: "border-[#2a2522] bg-[#1a1714] text-[#8a7d6d] hover:border-[#5a4f42]"
        ),
        else: "border-[#1a1714] border-dashed text-[#2a2522]"
      )
    ]}
    phx-click={if @bucket, do: "activate_bucket", else: nil}
    phx-value-index={@index}
    >
      <span class="text-[#5a4f42] opacity-50"><%= @index + 1 %></span>
      <%= if @bucket do %>
        <span class="truncate max-w-20"><%= truncate(@bucket.title, 12) %></span>
        <button
          phx-click="remove_bucket"
          phx-value-index={@index}
          class="text-[#5a4f42] hover:text-[#d4756a] ml-auto"
        >
          ×
        </button>
      <% else %>
        <span class="opacity-50">empty</span>
      <% end %>
    </div>
    """
  end

  # Discussion overlay
  defp discussion_overlay(assigns) do
    ~H"""
    <div class="absolute inset-0 bg-[#0a0908]/95 backdrop-blur-sm flex flex-col animate-fade-in">
      <!-- Header -->
      <div class="flex-none p-6 border-b border-[#1a1714]">
        <div class="flex items-center justify-between">
          <div>
            <h2 class="text-[#e8e0d5] text-lg font-mono"><%= @node.title %></h2>
            <%= if @node.description do %>
              <p class="text-[#5a4f42] text-sm font-mono mt-1"><%= @node.description %></p>
            <% end %>
          </div>
          <button
            phx-click="enter_discussion"
            phx-value-id={@node.id}
            class="px-4 py-2 bg-[#8b9a7d] text-[#0a0908] font-mono text-sm hover:bg-[#a0b090] transition-colors"
          >
            Enter Discussion →
          </button>
        </div>
      </div>

      <!-- Preview content -->
      <div class="flex-1 p-6 overflow-y-auto">
        <div class="max-w-2xl mx-auto">
          <p class="text-[#5a4f42] font-mono text-sm mb-4">
            Press <span class="text-[#8b9a7d]">Enter</span> or click the button to join the full conversation.
          </p>
          <p class="text-[#3a3530] font-mono text-sm">
            Press <span class="text-[#5a4f42]">Space</span> to return to the stream.
          </p>

          <!-- Activity info -->
          <div class="mt-8 p-4 border border-[#1a1714]">
            <div class="flex items-center gap-4 text-xs font-mono">
              <div class="flex items-center gap-2">
                <div class={["w-2 h-2 rounded-full", activity_dot_class(@node.activity.level)]}></div>
                <span class="text-[#5a4f42] uppercase"><%= @node.activity.level %></span>
              </div>
              <%= if @node.activity.count > 0 do %>
                <span class="text-[#3a3530]">·</span>
                <span class="text-[#5a4f42]"><%= @node.activity.count %> messages this hour</span>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Create node modal
  defp create_node_modal(assigns) do
    ~H"""
    <div class="absolute inset-0 bg-[#0a0908]/90 backdrop-blur-sm flex items-center justify-center z-50 animate-fade-in">
      <div class="w-full max-w-md border border-[#2a2522] bg-[#0d0b0a] p-6">
        <div class="flex items-center justify-between mb-6">
          <h2 class="text-[#c4b8a8] font-mono uppercase tracking-wide text-sm">New Discussion</h2>
          <button phx-click="close_create_node" class="text-[#5a4f42] hover:text-[#c4b8a8] text-xl">×</button>
        </div>

        <form phx-submit="create_node" class="flex flex-col gap-4">
          <div>
            <label class="block text-[#5a4f42] text-xs font-mono uppercase mb-2">Title</label>
            <input
              type="text"
              name="title"
              required
              maxlength="50"
              class="w-full bg-[#1a1714] border border-[#2a2522] px-3 py-2 text-[#e8e0d5] font-mono text-sm focus:border-[#8b9a7d] focus:outline-none"
              placeholder="What do you want to discuss?"
            />
          </div>

          <div>
            <label class="block text-[#5a4f42] text-xs font-mono uppercase mb-2">Description</label>
            <textarea
              name="description"
              rows="3"
              maxlength="200"
              class="w-full bg-[#1a1714] border border-[#2a2522] px-3 py-2 text-[#e8e0d5] font-mono text-sm focus:border-[#8b9a7d] focus:outline-none resize-none"
              placeholder="Optional context..."
            ></textarea>
          </div>

          <div>
            <label class="block text-[#5a4f42] text-xs font-mono uppercase mb-2">Type</label>
            <div class="grid grid-cols-2 gap-2">
              <%= for type <- ~w(discussion question debate quiet) do %>
                <label class="flex items-center gap-2 p-2 border border-[#2a2522] cursor-pointer hover:border-[#5a4f42] has-[:checked]:border-[#8b9a7d] has-[:checked]:bg-[#8b9a7d]/10">
                  <input type="radio" name="node_type" value={type} checked={type == "discussion"} class="sr-only" />
                  <span class={"w-2 h-2 rounded-full #{node_type_dot(type)}"}></span>
                  <span class="text-[#8a7d6d] text-xs font-mono capitalize"><%= type %></span>
                </label>
              <% end %>
            </div>
          </div>

          <div class="flex gap-2 mt-4">
            <button type="button" phx-click="close_create_node" class="flex-1 px-4 py-2 border border-[#2a2522] text-[#5a4f42] font-mono text-sm hover:border-[#5a4f42]">
              Cancel
            </button>
            <button type="submit" class="flex-1 px-4 py-2 bg-[#8b9a7d] text-[#0a0908] font-mono text-sm hover:bg-[#a0b090]">
              Create
            </button>
          </div>
        </form>
      </div>
    </div>
    """
  end

  # Resonance toast component
  defp resonance_toast(assigns) do
    is_positive = assigns.toast.amount > 0
    assigns = assign(assigns, :is_positive, is_positive)

    ~H"""
    <div class={[
      "px-4 py-2 border backdrop-blur-sm font-mono text-xs animate-slide-in-right",
      if(@is_positive,
        do: "bg-[#8b9a7d]/20 border-[#8b9a7d]/40 text-[#8b9a7d]",
        else: "bg-[#d4756a]/20 border-[#d4756a]/40 text-[#d4756a]"
      )
    ]}>
      <%= if @is_positive, do: "+", else: "" %><%= @toast.amount %>
      <span class="opacity-70 ml-2"><%= format_reason(@toast.reason) %></span>
    </div>
    """
  end

  # Helper functions
  defp activity_color(:buzzing), do: "text-[#c9a962]"
  defp activity_color(:active), do: "text-[#8b9a7d]"
  defp activity_color(:quiet), do: "text-[#5a4f42]"
  defp activity_color(:dormant), do: "text-[#3a3530]"

  defp activity_dot_class(:buzzing), do: "bg-[#c9a962] animate-pulse"
  defp activity_dot_class(:active), do: "bg-[#8b9a7d]"
  defp activity_dot_class(:quiet), do: "bg-[#5a4f42]"
  defp activity_dot_class(:dormant), do: "bg-[#3a3530]"

  defp node_type_dot("discussion"), do: "bg-[#c9a962]"
  defp node_type_dot("question"), do: "bg-[#7eb8da]"
  defp node_type_dot("debate"), do: "bg-[#d4756a]"
  defp node_type_dot("quiet"), do: "bg-[#8b9a7d]"
  defp node_type_dot(_), do: "bg-[#5a4f42]"

  defp truncate(nil, _), do: ""
  defp truncate(text, max) do
    if String.length(text) > max do
      String.slice(text, 0, max - 1) <> "…"
    else
      text
    end
  end

  defp format_reason(:affirm_received), do: "affirmed"
  defp format_reason(:dismiss_received), do: "dismissed"
  defp format_reason(reason) when is_atom(reason), do: reason |> Atom.to_string() |> String.replace("_", " ")
  defp format_reason(reason) when is_binary(reason), do: String.replace(reason, "_", " ")
  defp format_reason(_), do: "resonance"
end
