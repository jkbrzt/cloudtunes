import json

from tornado.web import RequestHandler

from cloudtunes import settings
from cloudtunes.users.sessions import Session


class BaseHandler(RequestHandler):

    _session = None

    def get_absolute_url(self, path):
        if '/' not in path:
            path = self.reverse_url(path)
        return '%s://%s%s' % (self.request.protocol,
                              self.request.host,
                              path)

    def get_current_user(self):
        from cloudtunes.users.models import User

        user_id = self.session['user']
        if user_id:
            assert user_id, user_id
            try:
                return User.objects.get(id=user_id)
            except User.DoesNotExist:
                pass

    @property
    def session(self):
        if not self._session:
            sid = self.get_secure_cookie(settings.SID_COOKIE)
            if sid:
                session = Session(sid)
                session.load()
            else:
                session = Session()
            self.set_secure_cookie(settings.SID_COOKIE, session.sid)
            self._session = session
        return self._session

    def on_finish(self):
        if self._session:
            self._session.save()

    def set_default_headers(self):
        self.set_header('Server', 'CloudTunes <3')


class ResourceHandler(BaseHandler):

    def initialize(self):
        if self.request.method in {'POST', 'PUT', 'PATCH'}:
            if 'json' not in self.request.headers['Content-Type']:
                pass
            self.request.data = json.loads(self.request.body)

    def set_default_headers(self):
        super(ResourceHandler, self).set_default_headers()
        self.set_header('Content-Type', 'application/json; charset=utf8')
