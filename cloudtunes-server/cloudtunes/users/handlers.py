from __future__ import absolute_import
import json

import tornado.web

from cloudtunes.base.handlers import ResourceHandler


class UserHandler(ResourceHandler):

    @tornado.web.authenticated
    def get(self):
        self.write(self.current_user.to_json())

    @tornado.web.authenticated
    def put(self):
        data = json.loads(self.request.body)
        fields = {
            'name',
            'email',
            'picture',
            'username',
            'location',
            'desktop_notifications',
            'confirm_exit',
        }
        if not fields.issuperset(set(data.keys())):
            return self.send_error(400)
        self.current_user.update_fields(**data)
        self.current_user.save()
        self.current_user.emit_change()


class LogoutHandler(ResourceHandler):

    def get(self):
        self.session['user'] = ''
        self.redirect('/')
