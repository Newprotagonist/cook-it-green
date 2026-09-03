// Enregistre le service worker et abonne l'appareil aux notifications.
// Une ligne PushSubscription par navigateur : l'app est mono-utilisateur,
// il n'y a pas de compte auquel rattacher l'abonnement.

const urlBase64ToUint8Array = (base64String) => {
  const padding = "=".repeat((4 - (base64String.length % 4)) % 4)
  const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/")
  const raw = window.atob(base64)
  return Uint8Array.from([...raw].map((c) => c.charCodeAt(0)))
}

const registerServiceWorker = async () => {
  if (!("serviceWorker" in navigator)) return null
  return navigator.serviceWorker.register("/service-worker", { scope: "/" })
}

const subscribe = async (registration, vapidPublicKey) => {
  if (!("PushManager" in window) || !vapidPublicKey) return
  if (Notification.permission === "denied") return

  const permission = Notification.permission === "granted"
    ? "granted"
    : await Notification.requestPermission()
  if (permission !== "granted") return

  const existing = await registration.pushManager.getSubscription()
  const subscription = existing || await registration.pushManager.subscribe({
    userVisibleOnly: true,
    applicationServerKey: urlBase64ToUint8Array(vapidPublicKey)
  })

  const json = subscription.toJSON()
  await fetch("/push_subscription", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      endpoint: subscription.endpoint,
      p256dh: json.keys.p256dh,
      auth: json.keys.auth
    })
  })
}

document.addEventListener("DOMContentLoaded", async () => {
  const registration = await registerServiceWorker()
  if (!registration) return
  const meta = document.querySelector('meta[name="vapid-public-key"]')
  const button = document.querySelector("[data-enable-push]")
  if (!button) return
  button.addEventListener("click", async () => {
    button.disabled = true
    button.textContent = "Activation…"
    await subscribe(registration, meta && meta.content)
    button.textContent = Notification.permission === "granted" ? "Notifications activées" : "Refusées par le navigateur"
  })
})
