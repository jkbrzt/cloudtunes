module.exports = (options)->

    {image, title, body} = options

    notifications = window.webkitNotifications

    if not notifications
        return

    show = ->
        n = notifications.createNotification(image, title, body)
        n.onclick = ->
            window.blur()
            window.focus()
        n.show()

    if notifications.checkPermission() is 0
        show()
    else
        notifications.requestPermission ->
            if notifications.checkPermission() is 0
                show()
