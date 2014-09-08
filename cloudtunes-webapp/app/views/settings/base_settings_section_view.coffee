SectionView = require 'views/page_section_view'


class BaseSettingsSectionView extends SectionView

    tagName: 'section'
    events:
        'submit form': 'submit'

    getTemplateData: ->
        ## toJSON is limited on user.
        @model.attributes

    getFormData: ->
        data = {}
        for fieldName in @fieldNames
            field = @$ "[name=#{fieldName}]"
            if field.is('[type=checkbox]')
                value = field.is(':checked')
            else
                value = field.val()
            data[fieldName] = value
        data

    submit: (e)=>
        data = @getFormData()
        @model.save data
        no


module.exports = BaseSettingsSectionView
