from cloudtunes.base.handlers import ResourceHandler


class ServiceAuthHandler(ResourceHandler):

    #noinspection PyMethodOverriding
    def initialize(self, service_name, popup=False):
        super(ServiceAuthHandler, self).initialize()
        self.service_name = service_name
        self._popup = popup

    @property
    def popup(self):
        return self.get_argument('popup', self._popup)

    def delete(self):
        if self.current_user:
            self.current_user[self.service_name] = None
            self.current_user.save()
            self.current_user.emit_change()

    def service_connected(self, user):
        self.session['user'] = str(user.id)
        user.emit_change()
        # TODO: make it nicer
        if self.popup:
            self.write('<script>window.close()</script>')
            self.finish()
        else:
            self.redirect('/')
