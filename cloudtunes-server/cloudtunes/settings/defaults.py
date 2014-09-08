import sys
from os import path
import logging
from tornado.options import parse_command_line, options, define

from cloudtunes.log import CloudtunesLogFormatter

PACKAGE_ROOT = path.dirname(path.dirname(__file__))
ROOT = path.dirname(PACKAGE_ROOT)


define('port', default=8001, help='run on the given port', type=int)


parse_command_line()

PORT = options.port


SID_COOKIE = '_'

MONGODB = {
    'host': 'localhost'
}

REDIS = {
    'host': 'localhost'
}


#############################################################
# Logging
#############################################################

logger = logging.getLogger('cloudtunes')
# Hide our messages from the root logger configured by tornado.
# They would be logged twice. Kinda hacky.
logger.parent = None
logger.setLevel(logging.DEBUG)
handler = logging.StreamHandler(stream=sys.stdout)
handler.setLevel(logging.DEBUG)
handler.setFormatter(CloudtunesLogFormatter())
logger.addHandler(handler)
del handler


#############################################################
# Facebook <https://developers.facebook.com/apps>
#############################################################

FACEBOOK_APP_ID = None
FACEBOOK_APP_SECRET = None
# https://developers.facebook.com/docs/authentication/permissions/
# We don't really need any permissions ATM.
FACEBOOK_PERMISSIONS = [
    # 'publish_actions',
    # 'user_actions.music',
    # 'friends_actions.music',
    # 'email',
]

#############################################################
# Dropbox <https://www.dropbox.com/developers>
#############################################################

DROPBOX_API_ACCESS_TYPE = 'app_folder'
DROPBOX_API_APP_KEY = None
DROPBOX_API_APP_SECRET = None


#############################################################
# Last.fm <http://www.last.fm/api/account>
#############################################################

LASTFM_API_KEY = None
LASTFM_API_SECRET = None


#############################################################
# Tornado
#############################################################

HOMEPAGE_SITE_DIR = path.realpath(ROOT + '/homepage')
WEB_APP_DIR = path.realpath(ROOT + '/../cloudtunes-webapp/public')

TORNADO_APP = {
    'cookie_secret': None,
    'login_url': '/auth',
    'template_path': path.join(PACKAGE_ROOT, 'templates'),
    'static_path': WEB_APP_DIR,
    'xsrf_cookies': False,  # TODO: enable
    'autoescape': 'xhtml_escape',
    'socket_io_port': PORT,
    'flash_policy_port': 10843,
    'flash_policy_file': path.join(ROOT, 'flashpolicy.xml'),
}

FLASH_POLICY_PORT = 10843
FLASH_POLICY_FILE = path.join(ROOT, 'flashpolicy.xml')


#############################################################

del path, logging, sys
