// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

// Hooks for Gridroom
const Hooks = {}

// Grid Canvas Hook - handles pan/zoom and player movement
Hooks.GridCanvas = {
  mounted() {
    this.isDragging = false
    this.lastX = 0
    this.lastY = 0
    this.keysPressed = new Set()
    this.moveInterval = null

    // Mouse events for panning
    this.el.addEventListener('mousedown', (e) => {
      if (e.target.closest('a')) return // Don't drag when clicking links
      this.isDragging = true
      this.lastX = e.clientX
      this.lastY = e.clientY
      this.el.style.cursor = 'grabbing'
    })

    window.addEventListener('mousemove', (e) => {
      if (!this.isDragging) return
      const dx = (e.clientX - this.lastX) * -1
      const dy = (e.clientY - this.lastY) * -1
      this.lastX = e.clientX
      this.lastY = e.clientY
      this.pushEvent('pan', { dx, dy })
    })

    window.addEventListener('mouseup', () => {
      this.isDragging = false
      this.el.style.cursor = 'default'
    })

    // Wheel for zooming
    this.el.addEventListener('wheel', (e) => {
      e.preventDefault()
      this.pushEvent('zoom', {
        delta: e.deltaY,
        x: e.clientX,
        y: e.clientY
      })
    }, { passive: false })

    // Keyboard movement (WASD / Arrow keys)
    this.handleKeyDown = (e) => {
      // Ignore if typing in an input
      if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return

      const key = e.key.toLowerCase()

      // Center on player (Space)
      if (key === ' ') {
        e.preventDefault()
        this.centerOnPlayer()
        return
      }

      // Create node (N)
      if (key === 'n') {
        e.preventDefault()
        this.pushEvent('open_create_node', {})
        return
      }

      // Close sidebar or deselect node (Escape)
      if (key === 'escape') {
        this.pushEvent('close_create_node', {})
        this.pushEvent('deselect_node', {})
        return
      }

      // Enter selected node (Enter)
      if (key === 'enter') {
        e.preventDefault()
        this.pushEvent('enter_selected_node', {})
        return
      }

      // Movement keys
      if (['w', 'a', 's', 'd', 'arrowup', 'arrowdown', 'arrowleft', 'arrowright'].includes(key)) {
        e.preventDefault()
        this.keysPressed.add(key)
        this.startMoving()
      }
    }

    this.handleKeyUp = (e) => {
      const key = e.key.toLowerCase()
      this.keysPressed.delete(key)
      if (this.keysPressed.size === 0) {
        this.stopMoving()
      }
    }

    window.addEventListener('keydown', this.handleKeyDown)
    window.addEventListener('keyup', this.handleKeyUp)

    // Touch events for mobile
    let lastTouchX = 0
    let lastTouchY = 0

    this.el.addEventListener('touchstart', (e) => {
      if (e.touches.length === 1) {
        lastTouchX = e.touches[0].clientX
        lastTouchY = e.touches[0].clientY
      }
    })

    this.el.addEventListener('touchmove', (e) => {
      if (e.touches.length === 1) {
        const dx = (e.touches[0].clientX - lastTouchX) * -1
        const dy = (e.touches[0].clientY - lastTouchY) * -1
        lastTouchX = e.touches[0].clientX
        lastTouchY = e.touches[0].clientY
        this.pushEvent('pan', { dx, dy })
      }
    })

    // Handle confirmed node entry - Fluid ripple transition
    this.handleEvent("confirm_enter_node", ({node_id}) => {
      // Create the transition overlay
      const overlay = document.createElement('div')
      overlay.className = 'fluid-transition'

      // Multiple ripple layers for depth
      overlay.innerHTML = `
        <div class="fluid-ripple fluid-ripple-1"></div>
        <div class="fluid-ripple fluid-ripple-2"></div>
        <div class="fluid-ripple fluid-ripple-3"></div>
        <div class="fluid-fade"></div>
      `
      document.body.appendChild(overlay)

      // Trigger the animation
      requestAnimationFrame(() => {
        overlay.classList.add('active')
      })

      // Remove overlay and navigate after animation
      setTimeout(() => {
        overlay.remove()
        this.pushEvent('navigate_to_node', { id: node_id })
      }, 1000)
    })

    // Cancel dwell when leaving node proximity
    this.handleEvent("cancel_dwell", () => {
      // Visual feedback handled by server updating dwell_progress
    })
  },

  destroyed() {
    window.removeEventListener('keydown', this.handleKeyDown)
    window.removeEventListener('keyup', this.handleKeyUp)
    this.stopMoving()
  },

  startMoving() {
    if (this.moveInterval) return

    this.moveInterval = setInterval(() => {
      let dx = 0, dy = 0

      if (this.keysPressed.has('w') || this.keysPressed.has('arrowup')) dy = -1
      if (this.keysPressed.has('s') || this.keysPressed.has('arrowdown')) dy = 1
      if (this.keysPressed.has('a') || this.keysPressed.has('arrowleft')) dx = -1
      if (this.keysPressed.has('d') || this.keysPressed.has('arrowright')) dx = 1

      // Normalize diagonal movement
      if (dx !== 0 && dy !== 0) {
        dx *= 0.707
        dy *= 0.707
      }

      if (dx !== 0 || dy !== 0) {
        this.pushEvent('move', { dx, dy })
      }
    }, 16) // ~60fps
  },

  stopMoving() {
    if (this.moveInterval) {
      clearInterval(this.moveInterval)
      this.moveInterval = null
    }
  },

  centerOnPlayer() {
    const playerX = parseFloat(this.el.dataset.playerX) || 0
    const playerY = parseFloat(this.el.dataset.playerY) || 0
    const viewportX = parseFloat(this.el.dataset.viewportX) || 0
    const viewportY = parseFloat(this.el.dataset.viewportY) || 0

    // Calculate the offset needed to center on player
    const dx = playerX - viewportX
    const dy = playerY - viewportY

    // Animate smoothly then re-enable camera follow
    this.animatePan(dx, dy, () => {
      this.pushEvent('enable_camera_follow', {})
    })
  },

  animatePan(targetDx, targetDy, onComplete) {
    const steps = 20
    const stepDx = targetDx / steps
    const stepDy = targetDy / steps
    let step = 0

    const animate = () => {
      if (step < steps) {
        // Ease out
        const progress = step / steps
        const ease = 1 - Math.pow(1 - progress, 3)
        const currentDx = stepDx * (1 + (1 - ease))
        const currentDy = stepDy * (1 + (1 - ease))

        this.pushEvent('pan', { dx: currentDx, dy: currentDy })
        step++
        requestAnimationFrame(animate)
      } else if (onComplete) {
        onComplete()
      }
    }

    requestAnimationFrame(animate)
  }
}

// Room entrance animation - Fluid ripple effect
Hooks.RoomEntrance = {
  mounted() {
    // Create ripple overlay
    const ripple = document.createElement('div')
    ripple.className = 'room-ripple'
    this.el.appendChild(ripple)

    // Remove ripple after animation completes
    setTimeout(() => {
      ripple.remove()
    }, 1200)
  }
}

// Scroll to bottom hook for messages
Hooks.ScrollToBottom = {
  mounted() {
    this.el.scrollTop = this.el.scrollHeight
  },
  updated() {
    this.el.scrollTop = this.el.scrollHeight
  }
}

// Copy to clipboard hook
Hooks.CopyToClipboard = {
  mounted() {
    this.el.addEventListener('click', () => {
      const text = this.el.dataset.copyText
      if (text && navigator.clipboard) {
        navigator.clipboard.writeText(text)
      }
    })
  }
}

// Typing indicator hook
Hooks.TypingIndicator = {
  mounted() {
    this.typingTimeout = null

    this.el.addEventListener('input', () => {
      // Send typing start
      this.pushEvent('typing_start', {})

      // Clear existing timeout
      if (this.typingTimeout) {
        clearTimeout(this.typingTimeout)
      }

      // Set timeout to stop typing after 2 seconds of no input
      this.typingTimeout = setTimeout(() => {
        this.pushEvent('typing_stop', {})
      }, 2000)
    })

    this.el.addEventListener('blur', () => {
      if (this.typingTimeout) {
        clearTimeout(this.typingTimeout)
      }
      this.pushEvent('typing_stop', {})
    })
  },

  destroyed() {
    if (this.typingTimeout) {
      clearTimeout(this.typingTimeout)
    }
  }
}

// Terminal Keys Hook - handles keyboard shortcuts for terminal interface
Hooks.TerminalKeys = {
  mounted() {
    // The keydown event is handled via phx-window-keydown
    // This hook provides any additional JS-side functionality

    // Handle localStorage for bucket persistence
    this.loadBuckets()

    // Save buckets when they change
    this.handleEvent("buckets_updated", ({buckets}) => {
      this.saveBuckets(buckets)
    })
  },

  loadBuckets() {
    try {
      const saved = localStorage.getItem('gridroom_buckets')
      if (saved) {
        const bucketIds = JSON.parse(saved)
        // Push to server to restore buckets
        this.pushEvent('restore_buckets', { bucket_ids: bucketIds })
      }
    } catch (e) {
      console.warn('Could not load saved buckets:', e)
    }
  },

  saveBuckets(buckets) {
    try {
      const bucketIds = buckets.map(b => b?.id || null)
      localStorage.setItem('gridroom_buckets', JSON.stringify(bucketIds))
    } catch (e) {
      console.warn('Could not save buckets:', e)
    }
  }
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// Clear input event handler
window.addEventListener("phx:clear_input", (e) => {
  const input = document.getElementById(e.detail.id)
  if (input) {
    input.value = ""
  }
})

// Feedback given event handler (affirm/dismiss)
window.addEventListener("phx:feedback_given", (e) => {
  const { message_id, type } = e.detail

  // Find the message element and add visual feedback
  const messageEl = document.querySelector(`[data-message-id="${message_id}"]`)
  if (messageEl) {
    // Add flash effect based on feedback type
    const flashClass = type === "affirm" ? "affirm-flash" : "dismiss-flash"
    messageEl.classList.add(flashClass)

    // Remove the class after animation
    setTimeout(() => {
      messageEl.classList.remove(flashClass)
    }, 600)
  }

  // Show toast notification
  const toast = document.createElement('div')
  toast.className = `feedback-toast feedback-toast-${type}`
  toast.innerHTML = type === "affirm"
    ? '<span class="text-[#8b9a7d]">✓</span> Affirmed'
    : '<span class="text-[#d4756a]">✕</span> Dismissed'

  document.body.appendChild(toast)

  // Trigger animation
  requestAnimationFrame(() => {
    toast.classList.add('show')
  })

  // Remove toast after delay
  setTimeout(() => {
    toast.classList.remove('show')
    setTimeout(() => toast.remove(), 300)
  }, 1500)
})

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

