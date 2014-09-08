BaseSettingsSectionView = require 'views/settings/base_settings_section_view'
template = require 'templates/settings/profile'


class ProfileView extends BaseSettingsSectionView
    name: 'Profile'
    className: 'profile'
    url: 'profile'
    template: template
    fieldNames: [
        'username'
        'picture'
        'location'
        'email'
        'name'
    ]


    events: _.extend
        'click .picture img': 'selectImage',
        BaseSettingsSectionView::events


    getTemplateData: ->
        services = []
        for id in ['facebook', 'lastfm']
            service = @model.get(id)
            if service
                services.push
                    id: id
                    connected: yes
                    name: service.name
                    picture: service.picture
                    selected: service.picture is @model.get('picture')
            else
                services.push
                    id: id
                    connected: no
                    name: id
                    picture: null
                    selected: no
        data = super
        data.services = services
        data

    selectImage: (e)->
        $img = $(e.currentTarget)
        @$('.picture img').removeClass('selected')
        $img.addClass('selected')
        @model.save('picture', $img.attr('src'))


module.exports = ProfileView
