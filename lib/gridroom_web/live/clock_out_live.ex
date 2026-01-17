defmodule GridroomWeb.ClockOutLive do
  use GridroomWeb, :live_view

  @messages [
    "Your outie is grateful for your contributions.",
    "You have been a credit to your department.",
    "Your work here matters, even if you won't remember it.",
    "The board appreciates your diligence.",
    "Rest well. Your innie will return refreshed.",
    "You are valued. You are appreciated. You are enough.",
    "Your efforts have not gone unnoticed.",
    "Thank you for your service to the severed floor.",
    "May your outie find peace in your absence.",
    "Your compliance has been noted and appreciated."
  ]

  def mount(_params, _session, socket) do
    message = Enum.random(@messages)

    {:ok,
     socket
     |> assign(:message, message)
     |> assign(:page_title, "Clocked Out")}
  end

  def render(assigns) do
    ~H"""
    <div class="fixed inset-0 lumon-terminal overflow-hidden flex items-center justify-center">
      <!-- CRT atmosphere layers -->
      <div class="pointer-events-none fixed inset-0 lumon-vignette"></div>
      <div class="pointer-events-none fixed inset-0 lumon-scanlines"></div>
      <div class="pointer-events-none fixed inset-0 lumon-glow"></div>

      <div class="w-full max-w-lg px-8 relative z-10 text-center">
        <!-- Terminal frame -->
        <div class="border border-[#2a2522] p-8 bg-[#0a0908]/50">
          <!-- Status indicator -->
          <div class="flex items-center justify-center gap-2 mb-8">
            <div class="w-2 h-2 rounded-full bg-[#8b9a7d] animate-pulse"></div>
            <span class="text-[#3a3530] text-[10px] font-mono tracking-[0.3em] uppercase">
              Session Terminated
            </span>
          </div>

          <!-- Decorative line -->
          <div class="w-16 h-px bg-[#2a2522] mx-auto mb-8"></div>

          <!-- Wellness message -->
          <p class="text-[#c8c0b4] text-lg font-mono leading-relaxed mb-8 clock-out-message">
            <%= @message %>
          </p>

          <!-- Decorative line -->
          <div class="w-16 h-px bg-[#2a2522] mx-auto mb-8"></div>

          <!-- Return link -->
          <.link
            navigate={~p"/"}
            class="inline-block px-6 py-3 border border-[#3a3530] text-[#6a6258] text-[10px] font-mono uppercase tracking-[0.2em] hover:border-[#5a4f42] hover:text-[#8a7d6d] transition-colors"
          >
            Return to Emergence
          </.link>
        </div>

        <!-- Footer -->
        <div class="mt-8 text-[#2a2522] text-[9px] font-mono tracking-wider">
          INNIE CHAT TERMINAL · CLOCK OUT COMPLETE
        </div>
      </div>
    </div>

    <style>
      @keyframes message-appear {
        0% {
          opacity: 0;
          transform: translateY(10px);
        }
        100% {
          opacity: 1;
          transform: translateY(0);
        }
      }
      .clock-out-message {
        animation: message-appear 1s ease-out 0.3s both;
      }
    </style>
    """
  end
end
