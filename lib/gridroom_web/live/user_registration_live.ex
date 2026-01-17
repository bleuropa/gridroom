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

    error = Phoenix.Flash.get(socket.assigns.flash, :error)

    {:ok,
     socket
     |> assign(:anonymous_user, anonymous_user)
     |> assign(:error, error)
     |> assign(:page_title, "Induction")}
  end

  def render(assigns) do
    ~H"""
    <div class="fixed inset-0 lumon-terminal overflow-hidden flex items-center justify-center">
      <!-- CRT atmosphere layers -->
      <div class="pointer-events-none fixed inset-0 lumon-vignette"></div>
      <div class="pointer-events-none fixed inset-0 lumon-scanlines"></div>
      <div class="pointer-events-none fixed inset-0 lumon-glow"></div>

      <div class="w-full max-w-md px-6 relative z-10">
        <!-- Boot sequence header -->
        <div class="text-center mb-10">
          <!-- Glitchy logo -->
          <div class="relative inline-block mb-8">
            <div class="boot-logo w-16 h-16 mx-auto relative">
              <!-- Outer ring - pulsing -->
              <svg viewBox="0 0 64 64" class="w-full h-full absolute inset-0">
                <circle
                  cx="32" cy="32" r="28"
                  fill="none"
                  stroke="#4a4540"
                  stroke-width="1"
                  stroke-dasharray="8 4"
                  class="animate-spin-slow"
                />
                <circle
                  cx="32" cy="32" r="24"
                  fill="none"
                  stroke="#3a3530"
                  stroke-width="0.5"
                  class="animate-pulse-slow"
                />
              </svg>
              <!-- Inner symbol - new innie -->
              <svg viewBox="0 0 64 64" class="w-full h-full absolute inset-0 glitch-flicker">
                <circle cx="32" cy="32" r="6" fill="#c9a962" opacity="0.9" />
                <circle cx="32" cy="32" r="10" fill="none" stroke="#c9a962" stroke-width="1" opacity="0.4" />
                <circle cx="32" cy="32" r="14" fill="none" stroke="#c9a962" stroke-width="0.5" opacity="0.2" />
              </svg>
            </div>
          </div>

          <!-- System messages -->
          <div class="space-y-1 mb-6">
            <p class="text-[#3a3530] text-[10px] font-mono tracking-wider boot-line-1">
              INNIE CHAT TERMINAL v2.1.0
            </p>
            <p class="text-[#c9a962]/60 text-[10px] font-mono tracking-wider boot-line-2">
              NEW INNIE INDUCTION PROTOCOL
            </p>
            <p class="text-[#4a4540] text-[10px] font-mono tracking-wider boot-line-3">
              ══════════════════════════════════
            </p>
          </div>

          <!-- Welcome message -->
          <h1 class="text-[#e8e0d5] text-xl font-mono tracking-wide mb-2 boot-line-4">
            Induction Process
          </h1>
          <p class="text-[#6a6258] text-xs font-mono boot-line-5">
            You are beginning your journey as an Innie.
          </p>
        </div>

        <!-- Glyph preview -->
        <%= if @anonymous_user do %>
          <div class="flex justify-center mb-6 boot-line-5">
            <div class="text-center p-4 border border-[#2a2522] bg-[#1a1714]/50">
              <div class="w-10 h-10 mx-auto mb-2 flex items-center justify-center">
                <svg viewBox="-20 -20 40 40" class="w-full h-full">
                  <circle r="10" fill={@anonymous_user.glyph_color} opacity="0.9" />
                </svg>
              </div>
              <p class="text-[#4a4540] text-[9px] font-mono tracking-wider uppercase">
                Assigned Glyph
              </p>
            </div>
          </div>
        <% end %>

        <!-- Error message -->
        <%= if @error do %>
          <div class="mb-6 p-3 border border-[#d4756a]/50 bg-[#d4756a]/10">
            <p class="text-[#d4756a] text-xs font-mono flex items-center gap-2">
              <span class="text-[10px]">▲</span>
              INDUCTION ERROR: <%= @error %>
            </p>
          </div>
        <% end %>

        <!-- Registration form - terminal style -->
        <form action={~p"/register"} method="post" class="space-y-6">
          <input type="hidden" name="_csrf_token" value={Phoenix.Controller.get_csrf_token()} />

          <div class="space-y-4">
            <div>
              <label for="username" class="block text-[#6a6258] text-[10px] font-mono tracking-wider uppercase mb-2">
                Select Designation
              </label>
              <input
                type="text"
                name="user[username]"
                id="username"
                class="w-full px-4 py-3 bg-transparent border border-[#2a2522]
                       text-[#e8e0d5] placeholder-[#3a3530] font-mono
                       focus:border-[#c9a962] focus:outline-none
                       transition-colors"
                placeholder="3-20 characters"
                autocomplete="username"
                required
              />
            </div>

            <div>
              <label for="password" class="block text-[#6a6258] text-[10px] font-mono tracking-wider uppercase mb-2">
                Create Access Code
              </label>
              <input
                type="password"
                name="user[password]"
                id="password"
                class="w-full px-4 py-3 bg-transparent border border-[#2a2522]
                       text-[#e8e0d5] placeholder-[#3a3530] font-mono
                       focus:border-[#c9a962] focus:outline-none
                       transition-colors"
                placeholder="8+ characters"
                autocomplete="new-password"
                required
              />
            </div>
          </div>

          <button
            type="submit"
            class="w-full py-3 border border-[#c9a962] text-[#c9a962]
                   text-sm font-mono uppercase tracking-wider
                   hover:bg-[#c9a962]/10 transition-colors"
          >
            [ Complete Induction ]
          </button>
        </form>

        <!-- Warning notice -->
        <div class="mt-6 p-3 border border-[#2a2522] bg-[#1a1714]/30">
          <p class="text-[#4a4540] text-[10px] font-mono leading-relaxed">
            <span class="text-[#c9a962]/60">NOTE:</span> Your outie cannot access this terminal.
            If you forget your access code, a new induction will be required.
            Your current session data will be preserved.
          </p>
        </div>

        <!-- Footer links -->
        <div class="mt-8 pt-6 border-t border-[#1a1714] text-center space-y-3">
          <p class="text-[#4a4540] text-[10px] font-mono">
            Already inducted?
            <.link navigate={~p"/login"} class="text-[#8b9a7d] hover:text-[#a8b89d] ml-1">
              Clock in →
            </.link>
          </p>
          <p class="text-[#3a3530] text-[10px] font-mono">
            <.link navigate={~p"/"} class="hover:text-[#5a4f42]">
              ← Return to emergence
            </.link>
          </p>
        </div>

        <!-- Status bar -->
        <div class="mt-8 flex items-center justify-center gap-4 text-[#2a2522] text-[9px] font-mono">
          <span>SYS:OK</span>
          <span>•</span>
          <span>INDUCTION:READY</span>
          <span>•</span>
          <span class="text-[#c9a962]/50">●</span>
        </div>
      </div>
    </div>

    <style>
      @keyframes spin-slow {
        from { transform: rotate(0deg); }
        to { transform: rotate(360deg); }
      }
      .animate-spin-slow {
        animation: spin-slow 20s linear infinite;
      }

      @keyframes pulse-slow {
        0%, 100% { opacity: 0.3; }
        50% { opacity: 0.6; }
      }
      .animate-pulse-slow {
        animation: pulse-slow 3s ease-in-out infinite;
      }

      @keyframes glitch-flicker {
        0%, 100% { opacity: 0.9; }
        92% { opacity: 0.9; }
        93% { opacity: 0.3; transform: translate(1px, 0); }
        94% { opacity: 0.9; transform: translate(-1px, 0); }
        95% { opacity: 0.4; }
        96% { opacity: 0.9; transform: translate(0, 0); }
      }
      .glitch-flicker {
        animation: glitch-flicker 5s ease-in-out infinite;
      }

      @keyframes boot-in {
        from { opacity: 0; transform: translateY(4px); }
        to { opacity: 1; transform: translateY(0); }
      }
      .boot-line-1 { animation: boot-in 0.3s ease-out 0.1s both; }
      .boot-line-2 { animation: boot-in 0.3s ease-out 0.2s both; }
      .boot-line-3 { animation: boot-in 0.3s ease-out 0.3s both; }
      .boot-line-4 { animation: boot-in 0.3s ease-out 0.5s both; }
      .boot-line-5 { animation: boot-in 0.3s ease-out 0.6s both; }
    </style>
    """
  end
end
