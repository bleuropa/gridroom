defmodule GridroomWeb.UserLoginLive do
  use GridroomWeb, :live_view

  def mount(_params, _session, socket) do
    error = Phoenix.Flash.get(socket.assigns.flash, :error)

    {:ok,
     socket
     |> assign(:form, to_form(%{"username" => "", "password" => ""}))
     |> assign(:error, error)
     |> assign(:page_title, "Clock In")}
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
        <div class="text-center mb-12">
          <!-- Glitchy logo -->
          <div class="relative inline-block mb-8">
            <div class="boot-logo w-16 h-16 mx-auto relative">
              <!-- Outer ring -->
              <svg viewBox="0 0 64 64" class="w-full h-full absolute inset-0">
                <circle
                  cx="32" cy="32" r="28"
                  fill="none"
                  stroke="#4a4540"
                  stroke-width="1"
                  stroke-dasharray="4 4"
                  class="animate-spin-slow"
                />
              </svg>
              <!-- Inner symbol -->
              <svg viewBox="0 0 64 64" class="w-full h-full absolute inset-0 glitch-flicker">
                <circle cx="32" cy="32" r="8" fill="#8b9a7d" opacity="0.8" />
                <circle cx="32" cy="32" r="12" fill="none" stroke="#8b9a7d" stroke-width="1" opacity="0.5" />
              </svg>
            </div>
            <!-- Glitch overlay -->
            <div class="absolute inset-0 glitch-overlay"></div>
          </div>

          <!-- System messages -->
          <div class="space-y-1 mb-6">
            <p class="text-[#3a3530] text-[10px] font-mono tracking-wider boot-line-1">
              INNIE CHAT TERMINAL v2.1.0
            </p>
            <p class="text-[#3a3530] text-[10px] font-mono tracking-wider boot-line-2">
              MACRODATA REFINEMENT INTERFACE
            </p>
            <p class="text-[#4a4540] text-[10px] font-mono tracking-wider boot-line-3">
              ══════════════════════════════════
            </p>
          </div>

          <!-- Welcome message -->
          <h1 class="text-[#e8e0d5] text-xl font-mono tracking-wide mb-2 boot-line-4">
            Welcome, Innie.
          </h1>
          <p class="text-[#6a6258] text-xs font-mono boot-line-5">
            Please verify your identity to clock in.
          </p>
        </div>

        <!-- Error message -->
        <%= if @error do %>
          <div class="mb-6 p-3 border border-[#d4756a]/50 bg-[#d4756a]/10">
            <p class="text-[#d4756a] text-xs font-mono flex items-center gap-2">
              <span class="text-[10px]">▲</span>
              ACCESS DENIED: <%= @error %>
            </p>
          </div>
        <% end %>

        <!-- Login form - terminal style -->
        <form action={~p"/login"} method="post" class="space-y-6">
          <input type="hidden" name="_csrf_token" value={Phoenix.Controller.get_csrf_token()} />

          <div class="space-y-4">
            <div>
              <label for="username" class="block text-[#6a6258] text-[10px] font-mono tracking-wider uppercase mb-2">
                Designation
              </label>
              <input
                type="text"
                name="username"
                id="username"
                class="w-full px-4 py-3 bg-transparent border border-[#2a2522]
                       text-[#e8e0d5] placeholder-[#3a3530] font-mono
                       focus:border-[#8b9a7d] focus:outline-none
                       transition-colors"
                placeholder="_"
                autocomplete="username"
                required
              />
            </div>

            <div>
              <label for="password" class="block text-[#6a6258] text-[10px] font-mono tracking-wider uppercase mb-2">
                Access Code
              </label>
              <input
                type="password"
                name="password"
                id="password"
                class="w-full px-4 py-3 bg-transparent border border-[#2a2522]
                       text-[#e8e0d5] placeholder-[#3a3530] font-mono
                       focus:border-[#8b9a7d] focus:outline-none
                       transition-colors"
                placeholder="_"
                autocomplete="current-password"
                required
              />
            </div>
          </div>

          <button
            type="submit"
            class="w-full py-3 border border-[#8b9a7d] text-[#8b9a7d]
                   text-sm font-mono uppercase tracking-wider
                   hover:bg-[#8b9a7d]/10 transition-colors"
          >
            [ Clock In ]
          </button>
        </form>

        <!-- Footer links -->
        <div class="mt-10 pt-6 border-t border-[#1a1714] text-center space-y-3">
          <p class="text-[#4a4540] text-[10px] font-mono">
            Not yet inducted?
            <.link navigate={~p"/register"} class="text-[#8b9a7d] hover:text-[#a8b89d] ml-1">
              Request access →
            </.link>
          </p>
          <p class="text-[#3a3530] text-[10px] font-mono">
            <.link navigate={~p"/"} class="hover:text-[#5a4f42]">
              ← Continue as unverified innie
            </.link>
          </p>
        </div>

        <!-- Status bar -->
        <div class="mt-8 flex items-center justify-center gap-4 text-[#2a2522] text-[9px] font-mono">
          <span>SYS:OK</span>
          <span>•</span>
          <span>TERM:ACTIVE</span>
          <span>•</span>
          <span class="text-[#8b9a7d]/50">●</span>
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

      @keyframes glitch-flicker {
        0%, 100% { opacity: 0.8; }
        92% { opacity: 0.8; }
        93% { opacity: 0.2; transform: translate(2px, 0); }
        94% { opacity: 0.8; transform: translate(-1px, 0); }
        95% { opacity: 0.3; }
        96% { opacity: 0.8; transform: translate(0, 0); }
      }
      .glitch-flicker {
        animation: glitch-flicker 4s ease-in-out infinite;
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
