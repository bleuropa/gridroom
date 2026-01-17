defmodule GridroomWeb.UserRegistrationLive do
  use GridroomWeb, :live_view

  alias Gridroom.Accounts

  def mount(_params, session, socket) do
    # Get anonymous user if exists (to show glyph preview)
    anonymous_user =
      case session["_csrf_token"] do
        nil -> nil
        token -> Accounts.get_user_by_session(token)
      end

    # Check for error flash from failed registration
    error = Phoenix.Flash.get(socket.assigns.flash, :error)

    {:ok,
     socket
     |> assign(:anonymous_user, anonymous_user)
     |> assign(:error, error)
     |> assign(:page_title, "Induction")}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-[#0d0b0a] flex items-center justify-center px-4">
      <div class="w-full max-w-sm">
        <!-- Header -->
        <div class="text-center mb-8">
          <p class="text-[#4a4540] text-[10px] font-mono tracking-[0.3em] uppercase mb-4">Innie Chat</p>
          <h1 class="text-[#e8e0d5] text-2xl font-light tracking-wide mb-2">Innie Induction</h1>
          <p class="text-[#8a7d6d] text-sm font-mono">Select your designation. No personal data required.</p>
        </div>

        <!-- Glyph preview -->
        <%= if @anonymous_user do %>
          <div class="flex justify-center mb-6">
            <div class="text-center">
              <div class="w-12 h-12 mx-auto mb-2 flex items-center justify-center">
                <svg viewBox="-20 -20 40 40" class="w-full h-full">
                  <circle r="12" fill={@anonymous_user.glyph_color} opacity="0.9" />
                </svg>
              </div>
              <p class="text-[#5a4f42] text-xs font-mono">Your glyph will be assigned</p>
            </div>
          </div>
        <% end %>

        <!-- Error message -->
        <%= if @error do %>
          <div class="mb-4 p-3 bg-[#2a1a1a] border border-[#d4756a] rounded-lg">
            <p class="text-[#d4756a] text-sm"><%= @error %></p>
          </div>
        <% end %>

        <!-- Registration form - posts to session controller -->
        <form action={~p"/register"} method="post" class="space-y-4">
          <input type="hidden" name="_csrf_token" value={Phoenix.Controller.get_csrf_token()} />

          <div>
            <label for="username" class="block text-[#c4b8a8] text-sm mb-1 font-mono">Designation</label>
            <input
              type="text"
              name="user[username]"
              id="username"
              class="w-full px-4 py-3 bg-[#1c1917] border border-[#2a2522] rounded-lg
                     text-[#e8e0d5] placeholder-[#5a4f42]
                     focus:border-[#c4915a] focus:ring-1 focus:ring-[#c4915a] focus:outline-none
                     transition-colors"
              placeholder="3-20 characters"
              autocomplete="username"
              required
            />
          </div>

          <div>
            <label for="password" class="block text-[#c4b8a8] text-sm mb-1 font-mono">Access Code</label>
            <input
              type="password"
              name="user[password]"
              id="password"
              class="w-full px-4 py-3 bg-[#1c1917] border border-[#2a2522] rounded-lg
                     text-[#e8e0d5] placeholder-[#5a4f42]
                     focus:border-[#c4915a] focus:ring-1 focus:ring-[#c4915a] focus:outline-none
                     transition-colors"
              placeholder="8+ characters"
              autocomplete="new-password"
              required
            />
          </div>

          <button
            type="submit"
            class="w-full py-3 bg-gradient-to-r from-[#dba76f] to-[#c4915a]
                   text-[#0d0b0a] font-medium rounded-lg
                   hover:from-[#e8b87a] hover:to-[#d4a06a]
                   transition-all duration-200
                   focus:outline-none focus:ring-2 focus:ring-[#dba76f] focus:ring-offset-2 focus:ring-offset-[#0d0b0a]"
          >
            Complete Induction
          </button>
        </form>

        <!-- Links -->
        <div class="mt-6 text-center space-y-2">
          <p class="text-[#5a4f42] text-sm font-mono">
            Already inducted?
            <.link navigate={~p"/login"} class="text-[#dba76f] hover:text-[#e8b87a]">
              Clock in
            </.link>
          </p>
          <p class="text-[#3a3530] text-xs font-mono">
            <.link navigate={~p"/"} class="hover:text-[#5a4f42]">
              ← Return to emergence
            </.link>
          </p>
        </div>

        <!-- Note -->
        <div class="mt-8 p-4 bg-[#1c1917] rounded-lg border border-[#2a2522]">
          <p class="text-[#5a4f42] text-xs leading-relaxed font-mono">
            Your outie has no access to this information. If you forget your access code,
            a new induction will be required.
          </p>
        </div>
      </div>
    </div>
    """
  end
end
