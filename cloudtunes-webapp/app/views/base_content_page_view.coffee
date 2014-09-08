{View, PageView} = require 'mvc'
template = require 'templates/page'


class BaseContentPageView extends PageView

    template: template
    className: 'content-page'
    pageName: null
    pageURL: null
    sections: null  # A list of `SectionView` instances.
    sectionsByURL: null  # Mapping built in `initialize()`.

    initialize: (options)->
        @sectionsByURL = {}
        for section in @getSections()
            @sectionsByURL[section::url] = section
        super options

    getSections: ->
        @sections

    getTemplateData: ->
        pageName: @pageName
        pageURL: @pageURL
        sections: for section in @getSections()
            name: section::name
            className: section::className
            url: if @pageURL then "/#{@pageURL}/#{section::url}" else "/#{section::url}"

    renderSection: ->
        sectionViewClass = @sectionsByURL[@options.section]

        if not sectionViewClass
            # If the requested section doesn't exist,
            # navigate to the first one
            fallback = @getSections()[0]
            Backbone.history.navigate(fallback::url)
            sectionViewClass = fallback

        section = new sectionViewClass({@model})
        @$('.content').append(section.render().el)
        @$("nav a.#{section.className}").addClass('active')
        @subview('section', section)


module.exports = BaseContentPageView
