pubsub = require 'pubsub'
BaseContentPageView = require 'views/base_content_page_view'
ProfileView = require 'views/settings/profile_view'
SocialView = require 'views/settings/social_view'
NotificationsView = require 'views/settings/notifications_view'


class SettingsPageView extends BaseContentPageView

    id: 'settings'
    pageName: 'Settings'
    pageURL: 'settings'
    sections: [
        ProfileView
        SocialView
        NotificationsView
    ]

    render: ->
        super
        @renderSection()

    getTemplateData: ->
        _.extend(super, user: @model)


module.exports = SettingsPageView
