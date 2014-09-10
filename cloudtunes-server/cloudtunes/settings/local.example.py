from os import path

from .defaults import *


DEBUG = False


MONGODB = {
    'host': 'localhost'
}


REDIS = {
    'host': 'localhost'
}


WEB_APP_DIR = path.realpath(ROOT + '/../cloudtunes-webapp/build/production')


TORNADO_APP.update({
    'static_path': WEB_APP_DIR,
    'debug': DEBUG,
    'cookie_secret': 'PLEASECHANGETHIS'
})


EMAIL = {
    'SMTP_SERVER': 'smtp.gmail.com',
    'SMTP_PORT': 587,
    'SENDER': None,
    'PASSWORD': None
}

#############################################################
# Facebook <https://developers.facebook.com/apps>
#############################################################

FACEBOOK_APP_ID = None
FACEBOOK_APP_SECRET = None

#############################################################
# Last.fm <http://www.last.fm/api/account>
#############################################################

LASTFM_API_KEY = None
LASTFM_API_SECRET = None

#############################################################
# Dropbox <https://www.dropbox.com/developers>
#############################################################

DROPBOX_API_APP_KEY = None
DROPBOX_API_APP_SECRET = None
