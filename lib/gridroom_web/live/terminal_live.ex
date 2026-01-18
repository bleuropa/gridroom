defmodule GridroomWeb.TerminalLive do
  @moduledoc """
  Lumon-inspired terminal interface for discovering discussions.

  Discussions are organized into MDR-style folders (Sports, Gossip, Tech, etc.)
  displayed at the top. Users refine through topics one at a time within each folder.
  Completing a folder triggers a Lumon wellness celebration.
  """

  use GridroomWeb, :live_view

  alias Gridroom.{Grid, Accounts, Folders}
  alias GridroomWeb.Presence

  @emerge_delay_ms 1200
  @title_materialize_ms 2500
  @post_title_pause 1500
  @description_surface_ms 2000
  @dismiss_delay_ms 600

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
      Process.send_after(self(), :emerge_next, @emerge_delay_ms)
    end

    # Load folders with progress
    folders_with_progress = Folders.list_folders_with_progress(user.id)

    # Find first non-completed folder, or first folder
    active_folder_index =
      Enum.find_index(folders_with_progress, fn fp -> !fp.completed end) || 0

    # Load user's saved buckets (slots 1-6) and created nodes (slots 7-8)
    buckets = load_user_buckets(user)
    created_nodes = load_user_created_nodes(user)
    bucket_ids = Enum.map(buckets, & &1.id) |> MapSet.new()
    created_node_ids = Enum.map(created_nodes, & &1.id) |> MapSet.new()

    # Load dismissed node IDs
    dismissed_ids = Accounts.list_dismissed_node_ids(user) |> MapSet.new()
    excluded_ids = dismissed_ids |> MapSet.union(bucket_ids) |> MapSet.union(created_node_ids)

    # Load nodes for the active folder
    {queue, active_folder} =
      load_folder_queue(folders_with_progress, active_folder_index, excluded_ids, user)

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:logged_in, user && user.username != nil)
     |> assign(:folders, folders_with_progress)
     |> assign(:active_folder_index, active_folder_index)
     |> assign(:active_folder, active_folder)
     |> assign(:queue, queue)
     |> assign(:current, nil)
     |> assign(:current_state, :void)
     |> assign(:buckets, buckets)
     |> assign(:created_nodes, created_nodes)
     |> assign(:new_bucket_index, nil)
     |> assign(:new_created_index, nil)
     |> assign(:active_bucket, nil)
     |> assign(:view_mode, :discover)
     |> assign(:drift_seed, :rand.uniform(1000))
     |> assign(:page_title, "Innie Chat")
     |> assign(:show_help, false)
     |> assign(:show_completion, false)
     |> assign(:completion_message, nil)
     |> assign(:excluded_ids, excluded_ids)
     |> assign(:show_create_modal, false)
     |> assign(:create_form, to_form(%{"title" => "", "description" => ""}))}
  end

  defp load_user_buckets(user) do
    user.bucket_ids
    |> Enum.map(&Grid.get_node_with_activity/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(fn node -> node.decay == :gone end)
  end

  defp load_user_created_nodes(user) do
    user.created_node_ids
    |> Enum.map(&Grid.get_node_with_activity/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(fn node -> node.decay == :gone end)
  end

  defp load_folder_queue(folders_with_progress, active_index, excluded_ids, user) do
    if Enum.empty?(folders_with_progress) do
      # No folders - load all nodes (fallback)
      nodes =
        Grid.list_nodes_with_activity()
        |> Enum.reject(fn node -> MapSet.member?(excluded_ids, node.id) end)
        |> Enum.shuffle()

      {nodes, nil}
    else
      folder_data = Enum.at(folders_with_progress, active_index)
      folder = folder_data.folder

      # Load today's nodes for this folder
      today = Date.utc_today()

      # For community folders, exclude the user's own discussions
      opts =
        if folder.is_community && user do
          [exclude_creator_id: user.id]
        else
          []
        end

      nodes =
        Folders.list_folder_nodes(folder.id, today, opts)
        |> Enum.map(&add_node_activity/1)
        |> Enum.reject(fn node -> MapSet.member?(excluded_ids, node.id) end)
        |> Enum.shuffle()

      {nodes, folder_data}
    end
  end

  defp add_node_activity(node) do
    # Add activity and decay info to node
    case Grid.get_node_with_activity(node.id) do
      nil -> node
      node_with_activity -> node_with_activity
    end
  end

  # Emergence flow
  @impl true
  def handle_info(:emerge_next, socket) do
    queue = socket.assigns.queue

    cond do
      # Showing completion message - don't emerge
      socket.assigns.show_completion ->
        {:noreply, socket}

      # Have topics in queue
      socket.assigns.view_mode == :discover and Enum.any?(queue) ->
        [next | rest] = queue
        total_time = @title_materialize_ms + @post_title_pause + @description_surface_ms
        Process.send_after(self(), :become_present, total_time)

        {:noreply,
         socket
         |> assign(:current, next)
         |> assign(:current_state, :emerging)
         |> assign(:queue, rest)
         |> assign(:drift_seed, :rand.uniform(1000))}

      # Queue empty - check if folder is complete (only if there were topics to refine)
      socket.assigns.view_mode == :discover and Enum.empty?(queue) and
          socket.assigns.active_folder != nil ->
        folder_data = socket.assigns.active_folder
        # Only show completion if the folder had topics (total > 0) and user refined them
        if folder_data.total > 0 and folder_data.refined > 0 do
          folder = folder_data.folder

          {:noreply,
           socket
           |> assign(:show_completion, true)
           |> assign(:completion_message, folder.completion_message)}
        else
          # Empty folder - just stay in void state
          {:noreply, socket}
        end

      true ->
        {:noreply, socket}
    end
  end

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
    Process.send_after(self(), :emerge_next, @dismiss_delay_ms)
    {:noreply, socket |> assign(:current, nil) |> assign(:current_state, :void)}
  end

  @impl true
  def handle_info({:node_created, node}, socket) do
    user = socket.assigns.user
    bucket_ids = Enum.map(socket.assigns.buckets, & &1.id)

    # Only add if in current folder and not dismissed/bucketed
    in_current_folder? =
      socket.assigns.active_folder != nil and
        node.folder_id == socket.assigns.active_folder.folder.id and
        node.folder_date == Date.utc_today()

    if in_current_folder? and not Accounts.node_dismissed?(user, node.id) and
         node.id not in bucket_ids do
      {:noreply, assign(socket, :queue, [node | socket.assigns.queue])}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:resonance_changed, _}, socket), do: {:noreply, socket}

  @impl true
  def handle_info(:clear_new_bucket, socket) do
    {:noreply, assign(socket, :new_bucket_index, nil)}
  end

  @impl true
  def handle_info(:clear_new_created, socket) do
    {:noreply, assign(socket, :new_created_index, nil)}
  end

  # Keybinds
  @impl true
  def handle_event("keydown", %{"key" => key}, socket) do
    folders = socket.assigns.folders

    cond do
      # Arrow keys work even during completion to switch folders
      socket.assigns.show_completion and key == "ArrowLeft" and length(folders) > 1 ->
        switch_folder(socket, :prev)

      socket.assigns.show_completion and key == "ArrowRight" and length(folders) > 1 ->
        switch_folder(socket, :next)

      # Other keys dismiss completion message
      socket.assigns.show_completion ->
        handle_completion_dismiss(socket)

      # Close help on any key
      socket.assigns.show_help ->
        {:noreply, assign(socket, :show_help, false)}

      # Close create modal on Escape
      socket.assigns.show_create_modal and key == "Escape" ->
        {:noreply, assign(socket, :show_create_modal, false)}

      true ->
        handle_keydown(key, socket)
    end
  end

  defp handle_keydown(key, socket) do
    has_current? = socket.assigns.current != nil
    in_discover? = socket.assigns.view_mode == :discover
    can_act? = socket.assigns.current_state in [:emerging, :present]
    folders = socket.assigns.folders

    cond do
      # Bucket current discussion
      key in [" ", "Enter"] and has_current? and in_discover? and can_act? ->
        bucket_current(socket)

      # Dismiss current discussion
      key in ["x", "X", "Backspace"] and has_current? and in_discover? and can_act? ->
        dismiss_current(socket)

      # Escape
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

      # Left arrow - previous folder
      key == "ArrowLeft" and length(folders) > 1 ->
        switch_folder(socket, :prev)

      # Right arrow - next folder
      key == "ArrowRight" and length(folders) > 1 ->
        switch_folder(socket, :next)

      # Tab - cycle folders
      key == "Tab" and length(folders) > 1 ->
        switch_folder(socket, :next)

      # Number keys 1-6 - enter bucketed discussion
      key in ~w(1 2 3 4 5 6) ->
        index = String.to_integer(key) - 1
        buckets = socket.assigns.buckets

        if index < length(buckets) do
          bucket = Enum.at(buckets, index)
          {:noreply, push_navigate(socket, to: "/node/#{bucket.id}")}
        else
          {:noreply, socket}
        end

      # Number keys 7-8 - enter created discussion
      key in ~w(7 8) ->
        index = String.to_integer(key) - 7
        created_nodes = socket.assigns.created_nodes

        if index < length(created_nodes) do
          node = Enum.at(created_nodes, index)
          {:noreply, push_navigate(socket, to: "/node/#{node.id}")}
        else
          {:noreply, socket}
        end

      # H - toggle help
      key in ["h", "H", "?"] ->
        {:noreply, assign(socket, :show_help, !socket.assigns.show_help)}

      # C - clear all buckets
      key in ["c", "C"] and length(socket.assigns.buckets) > 0 ->
        clear_all_buckets(socket)

      # N - create new discussion
      key in ["n", "N"] and socket.assigns.logged_in ->
        {:noreply, assign(socket, :show_create_modal, true)}

      true ->
        {:noreply, socket}
    end
  end

  defp switch_folder(socket, direction) do
    folders = socket.assigns.folders
    current_index = socket.assigns.active_folder_index
    max_index = length(folders) - 1

    new_index =
      case direction do
        :next -> if current_index >= max_index, do: 0, else: current_index + 1
        :prev -> if current_index <= 0, do: max_index, else: current_index - 1
      end

    excluded_ids = socket.assigns.excluded_ids
    user = socket.assigns.user
    {queue, active_folder} = load_folder_queue(folders, new_index, excluded_ids, user)

    # Cancel any pending emergence and restart
    socket =
      socket
      |> assign(:active_folder_index, new_index)
      |> assign(:active_folder, active_folder)
      |> assign(:queue, queue)
      |> assign(:current, nil)
      |> assign(:current_state, :void)
      |> assign(:show_completion, false)
      |> assign(:completion_message, nil)

    Process.send_after(self(), :emerge_next, @emerge_delay_ms)
    {:noreply, socket}
  end

  defp handle_completion_dismiss(socket) do
    # Move to next incomplete folder, or stay on current
    folders = socket.assigns.folders
    current_index = socket.assigns.active_folder_index

    # Find next incomplete folder
    next_incomplete =
      Enum.with_index(folders)
      |> Enum.find(fn {fp, i} -> i != current_index and !fp.completed end)

    socket =
      case next_incomplete do
        {_, new_index} ->
          excluded_ids = socket.assigns.excluded_ids
          user = socket.assigns.user
          {queue, active_folder} = load_folder_queue(folders, new_index, excluded_ids, user)

          socket
          |> assign(:active_folder_index, new_index)
          |> assign(:active_folder, active_folder)
          |> assign(:queue, queue)
          |> assign(:show_completion, false)
          |> assign(:completion_message, nil)

        nil ->
          # All folders complete
          socket
          |> assign(:show_completion, false)
          |> assign(:completion_message, nil)
      end

    Process.send_after(self(), :emerge_next, @emerge_delay_ms)
    {:noreply, socket}
  end

  # Click handlers
  @impl true
  def handle_event("bucket_current", _params, socket) do
    can_act? =
      socket.assigns.current != nil and socket.assigns.current_state in [:emerging, :present]

    if can_act?, do: bucket_current(socket), else: {:noreply, socket}
  end

  @impl true
  def handle_event("dismiss_current", _params, socket) do
    can_act? =
      socket.assigns.current != nil and socket.assigns.current_state in [:emerging, :present]

    if can_act?, do: dismiss_current(socket), else: {:noreply, socket}
  end

  @impl true
  def handle_event("select_folder", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)

    if index != socket.assigns.active_folder_index do
      folders = socket.assigns.folders
      excluded_ids = socket.assigns.excluded_ids
      user = socket.assigns.user
      {queue, active_folder} = load_folder_queue(folders, index, excluded_ids, user)

      socket =
        socket
        |> assign(:active_folder_index, index)
        |> assign(:active_folder, active_folder)
        |> assign(:queue, queue)
        |> assign(:current, nil)
        |> assign(:current_state, :void)
        |> assign(:show_completion, false)
        |> assign(:completion_message, nil)

      Process.send_after(self(), :emerge_next, @emerge_delay_ms)
      {:noreply, socket}
    else
      # If clicking on current folder and showing completion, dismiss it
      if socket.assigns.show_completion do
        {:noreply, socket |> assign(:show_completion, false) |> assign(:completion_message, nil)}
      else
        {:noreply, socket}
      end
    end
  end

  @impl true
  def handle_event("dismiss_completion", _params, socket) do
    handle_completion_dismiss(socket)
  end

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

  @impl true
  def handle_event("view_created", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    created_nodes = socket.assigns.created_nodes

    if index < length(created_nodes) do
      node = Enum.at(created_nodes, index)
      {:noreply, push_navigate(socket, to: "/node/#{node.id}")}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("enter_discussion", %{"id" => node_id}, socket) do
    {:noreply, push_navigate(socket, to: "/node/#{node_id}")}
  end

  @impl true
  def handle_event("return_to_discover", _params, socket) do
    socket = socket |> assign(:view_mode, :discover) |> assign(:active_bucket, nil)

    if socket.assigns.current == nil do
      Process.send_after(self(), :emerge_next, @dismiss_delay_ms)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("remove_bucket", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    user = socket.assigns.user

    {:ok, updated_user} = Accounts.remove_from_buckets(user, index)
    buckets = load_user_buckets(updated_user)

    socket =
      socket
      |> assign(:user, updated_user)
      |> assign(:buckets, buckets)

    socket =
      if socket.assigns.active_bucket == index do
        socket |> assign(:view_mode, :discover) |> assign(:active_bucket, nil)
      else
        socket
      end

    {:noreply, socket}
  end

  # Create discussion modal events
  @impl true
  def handle_event("open_create_modal", _params, socket) do
    if socket.assigns.logged_in do
      {:noreply, assign(socket, :show_create_modal, true)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("close_create_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_create_modal, false)
     |> assign(:create_form, to_form(%{"title" => "", "description" => ""}))}
  end

  @impl true
  def handle_event("create_discussion", %{"title" => title, "description" => description}, socket) do
    user = socket.assigns.user

    # Create the node
    attrs = %{
      title: String.trim(title),
      description: String.trim(description),
      created_by_id: user.id,
      position_x: 0.0,
      position_y: 0.0,
      node_type: "discussion"
    }

    case Grid.create_node(attrs) do
      {:ok, node} ->
        # Auto-add to created nodes (slots 7-8) if there's space
        case Accounts.add_to_created_nodes(user, node.id) do
          {:ok, updated_user} ->
            node_with_activity = Grid.get_node_with_activity(node.id)
            new_created_nodes = socket.assigns.created_nodes ++ [node_with_activity]

            {:noreply,
             socket
             |> assign(:user, updated_user)
             |> assign(:created_nodes, new_created_nodes)
             |> assign(:show_create_modal, false)
             |> assign(:create_form, to_form(%{"title" => "", "description" => ""}))
             |> assign(:new_created_index, length(new_created_nodes) - 1)
             |> push_navigate(to: "/node/#{node.id}")}

          {:error, :created_nodes_full} ->
            # Created nodes full (max 2), navigate to the node anyway
            {:noreply,
             socket
             |> assign(:show_create_modal, false)
             |> assign(:create_form, to_form(%{"title" => "", "description" => ""}))
             |> push_navigate(to: "/node/#{node.id}")}

          _ ->
            {:noreply,
             socket
             |> assign(:show_create_modal, false)
             |> assign(:create_form, to_form(%{"title" => "", "description" => ""}))
             |> push_navigate(to: "/node/#{node.id}")}
        end

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  # Private helpers
  defp bucket_current(socket) do
    current = socket.assigns.current
    user = socket.assigns.user

    case Accounts.add_to_buckets(user, current.id) do
      {:ok, updated_user} ->
        new_index = length(socket.assigns.buckets)
        new_buckets = socket.assigns.buckets ++ [current]

        # Update excluded IDs
        new_excluded = MapSet.put(socket.assigns.excluded_ids, current.id)

        # Track progress if in a folder
        track_folder_progress(socket, current)

        Process.send_after(self(), :dismiss_complete, 800)
        Process.send_after(self(), :clear_new_bucket, 1000)

        {:noreply,
         socket
         |> assign(:user, updated_user)
         |> assign(:buckets, new_buckets)
         |> assign(:new_bucket_index, new_index)
         |> assign(:current_state, :keeping)
         |> assign(:excluded_ids, new_excluded)}

      {:error, :buckets_full} ->
        {:noreply, socket}

      {:error, :already_bucketed} ->
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

    if current do
      Accounts.dismiss_node(user, current.id)

      # Update excluded IDs
      new_excluded = MapSet.put(socket.assigns.excluded_ids, current.id)

      # Track progress if in a folder
      track_folder_progress(socket, current)

      Process.send_after(self(), :dismiss_complete, @dismiss_delay_ms)

      {:noreply,
       socket |> assign(:current_state, :skipping) |> assign(:excluded_ids, new_excluded)}
    else
      {:noreply, socket}
    end
  end

  defp track_folder_progress(socket, node) do
    if socket.assigns.active_folder != nil and node.folder_id != nil do
      user = socket.assigns.user
      Folders.increment_progress(user.id, node.folder_id)
    end
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
      
    <!-- Folder navigation - top center -->
      <%= if length(@folders) > 0 do %>
        <.folder_nav
          folders={@folders}
          active_index={@active_folder_index}
        />
      <% end %>
      
    <!-- Emergence area - center of screen -->
      <div class="absolute inset-0 flex items-center justify-center">
        <%= cond do %>
          <% @show_completion -> %>
            <.completion_view
              message={@completion_message}
              folder={@active_folder && @active_folder.folder}
            />
          <% @view_mode == :discover -> %>
            <.emergence_view
              current={@current}
              state={@current_state}
              drift_seed={@drift_seed}
              queue_empty={Enum.empty?(@queue)}
              has_buckets={length(@buckets) > 0}
              folder={@active_folder && @active_folder.folder}
            />
          <% true -> %>
            <.bucket_view
              bucket={Enum.at(@buckets, @active_bucket)}
              index={@active_bucket}
            />
        <% end %>
      </div>
      
    <!-- Bucket indicators - bottom center -->
      <div class="absolute bottom-8 left-1/2 -translate-x-1/2 flex items-center gap-3">
        <!-- Slots 1-6: AI-generated buckets (sage green) -->
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
                else:
                  "border-[#8b9a7d]/60 text-[#8b9a7d]/80 hover:border-[#8b9a7d] hover:text-[#8b9a7d]"
              )
            ]}
            title={bucket.title}
          >
            {index + 1}
          </button>
        <% end %>

        <!-- Empty bucket slots (1-6) -->
        <%= if length(@buckets) < 6 do %>
          <%= for i <- length(@buckets)..5 do %>
            <div class="w-8 h-8 rounded-full border border-[#1a1714] border-dashed flex items-center justify-center text-[#1a1714] text-xs font-mono">
              {i + 1}
            </div>
          <% end %>
        <% end %>

        <!-- Separator between AI-generated and user-created -->
        <%= if @logged_in do %>
          <div class="w-px h-6 bg-[#2a2522] mx-1"></div>
        <% end %>

        <!-- Slots 7-8: User-created discussions (amber/gold) -->
        <%= if @logged_in do %>
          <%= for {created, index} <- Enum.with_index(@created_nodes) do %>
            <button
              phx-click="view_created"
              phx-value-index={index}
              class={[
                "w-8 h-8 rounded-full border flex items-center justify-center text-xs font-mono",
                if(@new_created_index == index,
                  do: "bucket-new-glow",
                  else: "transition-all duration-300"
                ),
                "border-[#c9a962]/60 text-[#c9a962]/80 hover:border-[#c9a962] hover:text-[#c9a962]"
              ]}
              title={created.title}
            >
              {index + 7}
            </button>
          <% end %>

          <!-- Empty created node slots (7-8) -->
          <%= if length(@created_nodes) < 2 do %>
            <%= for i <- (length(@created_nodes) + 1)..2 do %>
              <div class="w-8 h-8 rounded-full border border-[#2a2520]/40 border-dashed flex items-center justify-center text-[#2a2520]/60 text-xs font-mono">
                {i + 6}
              </div>
            <% end %>
          <% end %>

          <!-- Create button (only shown if user has < 2 created discussions) -->
          <%= if length(@created_nodes) < 2 do %>
            <button
              phx-click="open_create_modal"
              class="w-8 h-8 rounded-full border border-[#c9a962]/40 border-dashed flex items-center justify-center text-[#c9a962]/60 text-sm font-mono hover:border-[#c9a962] hover:text-[#c9a962] transition-colors"
              title="Create new discussion (n)"
            >
              +
            </button>
          <% end %>
        <% end %>
      </div>
      
    <!-- Queue indicator - top right -->
      <div class="absolute top-6 right-6 text-[#2a2522] text-xs font-mono">
        {length(@queue)} remaining
      </div>
      
    <!-- Help hint - bottom right -->
      <div class="absolute bottom-8 right-6">
        <button
          phx-click="keydown"
          phx-value-key="?"
          class="text-[#2a2522] hover:text-[#5a4f42] text-xs font-mono transition-colors"
        >
          {if @show_help, do: "hide", else: "?"}
        </button>
      </div>
      
    <!-- Help overlay -->
      <%= if @show_help do %>
        <.help_overlay has_folders={length(@folders) > 0} logged_in={@logged_in} />
      <% end %>
      
    <!-- Create discussion modal -->
      <%= if @show_create_modal do %>
        <.create_discussion_modal form={@create_form} />
      <% end %>
      
    <!-- Auth - top left -->
      <div class="absolute top-6 left-6 flex items-center gap-6">
        <span class="text-[#4a4540] text-[10px] font-mono tracking-[0.3em] uppercase">
          Innie Chat
        </span>
        <%= if @logged_in do %>
          <span class="text-[#5a4f42] text-xs font-mono tracking-wider">{@user.username}</span>
          <.link
            href={~p"/logout"}
            method="delete"
            class="text-[#3a3530] hover:text-[#5a4f42] text-[10px] font-mono tracking-wider uppercase"
          >
            clock out
          </.link>
        <% else %>
          <.link
            navigate={~p"/login"}
            class="text-[#3a3530] hover:text-[#5a4f42] text-[10px] font-mono tracking-wider uppercase"
          >
            clock in
          </.link>
          <.link
            navigate={~p"/register"}
            class="text-[#3a3530] hover:text-[#5a4f42] text-[10px] font-mono tracking-wider uppercase"
          >
            request access
          </.link>
        <% end %>
      </div>
    </div>
    """
  end

  # Folder navigation component
  defp folder_nav(assigns) do
    ~H"""
    <div class="absolute top-16 left-1/2 -translate-x-1/2 flex items-center gap-1">
      <%= for {folder_data, index} <- Enum.with_index(@folders) do %>
        <button
          phx-click="select_folder"
          phx-value-index={index}
          class={[
            "px-4 py-2 font-mono text-xs uppercase tracking-wider transition-all duration-300 border-b-2",
            folder_tab_classes(folder_data, index == @active_index)
          ]}
          title={folder_data.folder.description}
        >
          <span class="flex items-center gap-2">
            {folder_data.folder.name}
            <%= if folder_data.completed do %>
              <span class="text-[#8b9a7d]">&#10003;</span>
            <% else %>
              <span class="text-[#3a3530] text-[10px]">
                {folder_data.refined}/{folder_data.total}
              </span>
            <% end %>
          </span>
        </button>
      <% end %>
    </div>
    """
  end

  defp folder_tab_classes(folder_data, is_active) do
    cond do
      folder_data.completed and is_active ->
        "text-[#8b9a7d] border-[#8b9a7d] bg-[#8b9a7d]/5"

      folder_data.completed ->
        "text-[#5a6d4d] border-transparent hover:border-[#5a6d4d]/50"

      is_active ->
        "text-[#e8e0d4] border-[#8a7d6d]"

      true ->
        "text-[#5a4f42] border-transparent hover:text-[#8a7d6d] hover:border-[#3a3530]"
    end
  end

  # Completion celebration view
  defp completion_view(assigns) do
    ~H"""
    <div class="relative w-full max-w-xl px-8 animate-fade-in text-center">
      <!-- Folder completed badge -->
      <div class="mb-8">
        <div class="inline-flex items-center gap-3 px-6 py-3 border border-[#8b9a7d] bg-[#8b9a7d]/10 rounded-full">
          <span class="text-[#8b9a7d] text-lg">&#10003;</span>
          <span class="text-[#8b9a7d] text-sm font-mono uppercase tracking-wider">
            {@folder && @folder.name} Complete
          </span>
        </div>
      </div>
      
    <!-- Wellness message -->
      <div class="space-y-6 max-w-md mx-auto">
        <%= for paragraph <- String.split(@message || "", "\n\n", trim: true) do %>
          <p class="text-[#c9c0b0] text-base font-light leading-relaxed">
            {paragraph}
          </p>
        <% end %>
      </div>
      
    <!-- Continue hint -->
      <div class="mt-12">
        <button
          phx-click="dismiss_completion"
          class="text-[#5a4f42] hover:text-[#8a7d6d] text-xs font-mono uppercase tracking-wider transition-colors"
        >
          press any key to continue
        </button>
      </div>
    </div>
    """
  end

  # The emerging discussion
  defp emergence_view(assigns) do
    ~H"""
    <div class="relative w-full max-w-2xl px-8">
      <%= if @current do %>
        <div class={emergence_container_classes(@state)}>
          <!-- Title -->
          <h2 class={[
            "text-xl md:text-3xl font-mono font-normal tracking-wide text-center leading-relaxed",
            title_classes(@state)
          ]}>
            {@current.title}
          </h2>
          
    <!-- Description -->
          <%= if @current.description && @current.description != "" do %>
            <p class={[
              "text-center text-sm font-mono font-light leading-relaxed mt-10 max-w-lg mx-auto",
              description_classes(@state)
            ]}>
              {@current.description}
            </p>
          <% end %>
          
    <!-- Action hints -->
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
        <!-- Void state -->
        <div class="w-full flex items-center justify-center">
          <%= if @queue_empty do %>
            <div class="text-center space-y-8 animate-fade-in">
              <%= if @folder do %>
                <p class="text-[#4a4540] text-xs font-mono tracking-[0.3em] uppercase">
                  {@folder.name} folder empty
                </p>
              <% else %>
                <p class="text-[#4a4540] text-xs font-mono tracking-[0.3em] uppercase">
                  all topics reviewed
                </p>
              <% end %>
              <div class="w-8 h-px bg-[#2a2522] mx-auto"></div>
              <%= if @has_buckets do %>
                <p class="text-[#3a3530] text-[10px] font-mono tracking-widest">
                  your selections await
                </p>
              <% else %>
                <p class="text-[#3a3530] text-[10px] font-mono tracking-widest">
                  try another folder or return later
                </p>
              <% end %>
            </div>
          <% else %>
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
          <div class="text-[#5a4f42] text-xs font-mono mb-6">
            bucket {@index + 1}
          </div>

          <h2 class="text-2xl md:text-3xl font-light tracking-wide text-[#e8e0d5] mb-4">
            {@bucket.title}
          </h2>

          <%= if @bucket.description && @bucket.description != "" do %>
            <p class="text-[#8a7d6d] text-sm md:text-base font-light max-w-md mx-auto mb-8">
              "{@bucket.description}"
            </p>
          <% end %>

          <div class="flex items-center justify-center gap-2 mb-8">
            <div class={["w-1.5 h-1.5 rounded-full", activity_dot(@bucket.activity.level)]}></div>
            <span class="text-[#3a3530] text-[10px] font-mono uppercase tracking-wider">
              {@bucket.activity.level}
              <%= if @bucket.activity.count > 0 do %>
                · {@bucket.activity.count} messages
              <% end %>
            </span>
          </div>

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
          <%= if @has_folders do %>
            <div class="flex items-center gap-4">
              <span class="w-20 text-right text-[#5a4f42] text-xs font-mono">&#8592; &#8594;</span>
              <span class="text-[#8a7d6d] text-sm">switch folder</span>
            </div>
          <% end %>
          <div class="flex items-center gap-4">
            <span class="w-20 text-right text-[#5a4f42] text-xs font-mono">1-6</span>
            <span class="text-[#8a7d6d] text-sm">enter saved discussion</span>
          </div>
          <%= if @logged_in do %>
            <div class="flex items-center gap-4">
              <span class="w-20 text-right text-[#c9a962] text-xs font-mono">7-8</span>
              <span class="text-[#8a7d6d] text-sm">enter your discussion</span>
            </div>
          <% end %>
          <div class="flex items-center gap-4">
            <span class="w-20 text-right text-[#5a4f42] text-xs font-mono">c</span>
            <span class="text-[#8a7d6d] text-sm">clear all saved</span>
          </div>
          <%= if @logged_in do %>
            <div class="flex items-center gap-4">
              <span class="w-20 text-right text-[#5a4f42] text-xs font-mono">n</span>
              <span class="text-[#8a7d6d] text-sm">create discussion</span>
            </div>
          <% end %>
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

  # Create discussion modal
  defp create_discussion_modal(assigns) do
    ~H"""
    <div
      class="fixed inset-0 bg-[#080706]/95 flex items-center justify-center z-50 animate-fade-in"
      phx-click="close_create_modal"
    >
      <div
        class="bg-[#0d0c0a] border border-[#2a2522] rounded-lg p-8 max-w-md w-full mx-4"
        phx-click-away="close_create_modal"
        onclick="event.stopPropagation()"
      >
        <h3 class="text-[#e8e0d4] text-lg font-mono uppercase tracking-wider mb-6 text-center">
          Create Discussion
        </h3>

        <form phx-submit="create_discussion" class="space-y-6">
          <div>
            <label class="block text-[#5a4f42] text-xs font-mono uppercase tracking-wider mb-2">
              Title
            </label>
            <input
              type="text"
              name="title"
              id="create-discussion-title"
              class="w-full bg-[#0a0908] border border-[#2a2522] rounded px-4 py-3 text-[#e8e0d4] text-sm font-mono placeholder-[#3a3530] focus:border-[#8b9a7d] focus:outline-none"
              placeholder="What do you want to discuss?"
              required
              autofocus
              phx-hook="CreateDiscussionInput"
            />
          </div>

          <div>
            <label class="block text-[#5a4f42] text-xs font-mono uppercase tracking-wider mb-2">
              Description <span class="text-[#3a3530]">(optional)</span>
            </label>
            <textarea
              name="description"
              rows="3"
              class="w-full bg-[#0a0908] border border-[#2a2522] rounded px-4 py-3 text-[#e8e0d4] text-sm font-mono placeholder-[#3a3530] focus:border-[#8b9a7d] focus:outline-none resize-none"
              placeholder="Add some context..."
            ></textarea>
          </div>

          <div class="flex items-center justify-end gap-4 pt-2">
            <button
              type="button"
              phx-click="close_create_modal"
              class="px-4 py-2 text-[#5a4f42] text-sm font-mono uppercase tracking-wider hover:text-[#8a7d6d] transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              class="px-6 py-2 bg-[#8b9a7d] text-[#0d0c0a] text-sm font-mono uppercase tracking-wider hover:bg-[#9baa8d] transition-colors rounded"
            >
              Create
            </button>
          </div>
        </form>

        <p class="text-[#3a3530] text-[10px] font-mono mt-6 text-center">
          <span class="text-[#5a4f42]">esc</span> to cancel
        </p>
      </div>
    </div>
    """
  end

  # Helper functions
  defp emergence_container_classes(:keeping), do: "severance-keeping"
  defp emergence_container_classes(:skipping), do: "severance-skipping"
  defp emergence_container_classes(_), do: ""

  defp title_classes(:emerging), do: "severance-title-emerging text-[#e0d8cc]"
  defp title_classes(:present), do: "severance-title-present text-[#e8e0d4]"
  defp title_classes(:keeping), do: "severance-title-present text-[#e8e0d4]"
  defp title_classes(:skipping), do: "text-[#e8e0d4]"
  defp title_classes(_), do: "opacity-0"

  defp description_classes(:emerging), do: "severance-description-emerging text-[#9a9488]"
  defp description_classes(:present), do: "severance-description-present text-[#a8a298]"
  defp description_classes(:keeping), do: "text-[#a8a298]"
  defp description_classes(:skipping), do: "text-[#a8a298]"
  defp description_classes(_), do: "opacity-0"

  defp activity_dot(:buzzing), do: "bg-[#c9a962] animate-pulse"
  defp activity_dot(:active), do: "bg-[#8b9a7d]"
  defp activity_dot(:quiet), do: "bg-[#5a4f42]"
  defp activity_dot(:dormant), do: "bg-[#3a3530]"
end
