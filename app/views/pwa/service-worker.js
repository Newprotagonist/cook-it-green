// Service worker : notifications push et cache applicatif minimal.

self.addEventListener("push", (event) => {
  if (!event.data) return
  const payload = event.data.json()
  event.waitUntil(
    self.registration.showNotification(payload.title, {
      body: payload.body,
      icon: payload.icon,
      badge: payload.badge,
      tag: payload.tag,
      data: { url: payload.url || "/" }
    })
  )
})

self.addEventListener("notificationclick", (event) => {
  event.notification.close()
  const target = event.notification.data && event.notification.data.url ? event.notification.data.url : "/"
  event.waitUntil(
    clients.matchAll({ type: "window", includeUncontrolled: true }).then((list) => {
      for (const client of list) {
        if (new URL(client.url).pathname === target && "focus" in client) return client.focus()
      }
      if (clients.openWindow) return clients.openWindow(target)
    })
  )
})
