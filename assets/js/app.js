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
      const key = e.key.toLowerCase()

      // Center on player (Space or C)
      if (key === ' ' || key === 'c') {
        e.preventDefault()
        this.centerOnPlayer()
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

    // Handle node entry animation
    this.handleEvent("entering_node", ({node_id}) => {
      this.el.classList.add('entering-node')

      // Add zoom effect to the entering node
      const nodeEl = document.querySelector(`[data-node-id="${node_id}"]`)
      if (nodeEl) {
        nodeEl.classList.add('node-entering')
      }

      // Navigate after animation
      setTimeout(() => {
        this.pushEvent('navigate_to_node', { id: node_id })
      }, 800)
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

    // Animate smoothly by sending incremental pan events
    this.animatePan(dx, dy)
  },

  animatePan(targetDx, targetDy) {
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
      }
    }

    requestAnimationFrame(animate)
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

