from tornado.web import StaticFileHandler

from cloudtunes import settings
from cloudtunes.base.handlers import BaseHandler


class MainHandler(BaseHandler):

    def get(self):

        webapp_dir = self.settings['static_path']
        homepage_dir = settings.HOMEPAGE_SITE_DIR

        if self.current_user:
            app_dir = webapp_dir
        else:
            if self.request.path != '/':
                return self.redirect('/')
            app_dir = homepage_dir

        with open(app_dir + '/index.html') as f:
            self.write(f.read())


class NoCacheStaticFileHandler(StaticFileHandler):

    def set_extra_headers(self, path):
        self.set_header('Cache-control', 'no-cache')

