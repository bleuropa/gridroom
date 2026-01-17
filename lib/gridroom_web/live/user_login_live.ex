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
          <!-- Terminal logo -->
          <div class="relative inline-block mb-8">
            <div class="w-20 h-20 mx-auto relative">
              <svg viewBox="0 0 80 80" class="w-full h-full">
                <!-- Outer frame -->
                <rect x="8" y="8" width="64" height="64" fill="none" stroke="#2a2522" stroke-width="1" />
                <rect x="12" y="12" width="56" height="56" fill="none" stroke="#3a3530" stroke-width="0.5" />

                <!-- Terminal cursor/prompt -->
                <rect x="24" y="35" width="4" height="10" fill="#8b9a7d" class="terminal-cursor" />

                <!-- Decorative scan line -->
                <line x1="20" y1="28" x2="60" y2="28" stroke="#2a2522" stroke-width="0.5" />
                <line x1="20" y1="52" x2="60" y2="52" stroke="#2a2522" stroke-width="0.5" />

                <!-- Status indicator -->
                <circle cx="56" cy="20" r="2" fill="#8b9a7d" opacity="0.8" class="status-blink" />
              </svg>
            </div>
          </div>

          <!-- System messages -->
          <div class="space-y-1 mb-6">
            <p class="text-[#3a3530] text-[10px] font-mono tracking-wider boot-line-1">
              INNIE CHAT TERMINAL v2.1.0
            </p>
            <p class="text-[#4a4540] text-[10px] font-mono tracking-wider boot-line-2">
              ════════════════════════════
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
                Name
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
      @keyframes cursor-blink {
        0%, 50% { opacity: 1; }
        51%, 100% { opacity: 0; }
      }
      .terminal-cursor {
        animation: cursor-blink 1s step-end infinite;
      }

      @keyframes status-blink {
        0%, 90% { opacity: 0.8; }
        95% { opacity: 0.3; }
        100% { opacity: 0.8; }
      }
      .status-blink {
        animation: status-blink 3s ease-in-out infinite;
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
