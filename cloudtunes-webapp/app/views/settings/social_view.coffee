BaseSettingsSectionView = require 'views/settings/base_settings_section_view'
template = require 'templates/settings/social'


class SocialView extends BaseSettingsSectionView

    className: 'social'
    url: 'social'
    name: 'Social'
    template: template
    events:
        'click .connect': 'connectService'
        'click .remove': 'removeService'

    initialize: (options)->
        super options
        @listenTo @model, 'change', @render

    connectService: (e)->
        width = 650
        height = 350
        left = (screen.width / 2) - (width / 2)
        top = (screen.height / 2) - (height / 2)
        window.open e.currentTarget.href, '_blank',
                "width=#{width}, height=#{height}, left=#{left}, top=#{top}"
        no

    removeService: (e)->
        $.ajax
            url: e.currentTarget.href
            type: 'DELETE'
        no


module.exports = SocialView
