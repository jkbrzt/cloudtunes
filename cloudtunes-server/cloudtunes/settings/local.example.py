from os import path

from .defaults import *


DEBUG = False

FACEBOOK_APP_ID = None
FACEBOOK_APP_SECRET = None


LASTFM_API_KEY = None
LASTFM_API_SECRET = None

DROPBOX_API_APP_KEY = None
DROPBOX_API_APP_SECRET = None

MONGODB = {
    'host': 'localhost'
}
REDIS = {
    'host': 'localhost'
}
WEB_APP_DIR = path.realpath(path.join(
    ROOT, '..',
    'spa', 'build', 'development'
))
TORNADO_APP.update({
    'static_path': WEB_APP_DIR,
    'debug': DEBUG,
    'cookie_secret': None
})


EMAIL = {
    'SMTP_SERVER': 'smtp.gmail.com',
    'SMTP_PORT': 587,
    'SENDER': None,
    'PASSWORD': None
}
