BaseSettingsSectionView = require 'views/settings/base_settings_section_view'
template = require 'templates/settings/notifications'


class NotificationsView extends BaseSettingsSectionView
    className: 'notifications'
    url: 'notifications'
    name: 'Notifications'
    template: template
    fieldNames: [
        'desktop_notifications',
        'confirm_exit'
    ]
    events:
        'change input': 'submit'


module.exports = NotificationsView
