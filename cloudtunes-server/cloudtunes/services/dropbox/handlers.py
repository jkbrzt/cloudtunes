"""

https://www.dropbox.com/developers/start/authentication#python

"""
from datetime import datetime

import tornado.web
import tornado.gen

from cloudtunes.base.handlers import ResourceHandler
from cloudtunes import sync
from cloudtunes.library.models import Track
from cloudtunes.services.dropbox.client import Client
from cloudtunes.services.handlers import ServiceAuthHandler
from cloudtunes.users.models import User
from .client import Session
from .sync import sync_account
from .models import DropboxAccount


class DropboxAuthHandler(ServiceAuthHandler):

    def get(self):
        session = Session()
        request_token = session.obtain_request_token()

        callback_url = self.get_absolute_url(
            self.reverse_url('dropbox_callback'))

        if self.popup:
            callback_url += '?popup=1'

        url = session.build_authorize_url(
            request_token=request_token,
            oauth_callback=callback_url
        )

        self.session['dropbox_tmp_key'] = request_token.key
        self.session['dropbox_tmp_secret'] = request_token.secret

        self.redirect(url)

    def delete(self):
        super(DropboxAuthHandler, self).delete()
        if self.current_user:
            user = self.current_user
            Track.objects.filter(user=user.pk, source='dropbox').delete()
            user.emit('sync', 'dropbox:reset')


class DropboxAuthCallbackHandler(ServiceAuthHandler):

    def get(self):

        key = self.session.pop('dropbox_tmp_key', None)
        secret = self.session.pop('dropbox_tmp_secret', None)

        if not (key and secret):
            return self.redirect(self.reverse_url('dropbox', 'start'))

        # Fetch account info
        # TODO: async
        session = Session()
        session.set_request_token(key, secret)
        access_token = session.obtain_access_token(session.token)
        # https://www.dropbox.com/developers/reference/api#account-info
        info = Client(session).account_info()

        try:
            user = User.objects.get(dropbox__id=info['uid'])
        except User.DoesNotExist:
            if self.current_user:
                # Connect
                user = self.current_user
                user.dropbox = DropboxAccount()
            else:
                # Sign up
                name = info.get('display_name', '')
                user = User(
                    name=name,
                    dropbox=DropboxAccount()
                )

        user.dropbox.update_fields(
            id=info['uid'],
            display_name=info['display_name'],
            country=info.get('country', None),
            oauth_token_key=access_token.key,
            oauth_token_secret=access_token.secret,
        )
        user.save()

        sync_account.delay(user.dropbox.id)
        self.service_connected(user)


class PlayHandler(ResourceHandler):

    @tornado.gen.coroutine
    @tornado.web.authenticated
    def get(self, track_id):

        user = self.current_user

        track = Track.objects.get(id=track_id, user=user)

        if not track:
            # TODO: check owner and source!
            raise tornado.web.HTTPError(
                404, 'track "%s" not found' % track_id)

        url_key = 'dropbox_url:%s' % track_id

        url = sync.redis.get(url_key)
        if url:
            self.redirect(url)
            return

        client = Client.for_account(user.dropbox)

        response = yield tornado.gen.Task(
            client.media_async,
            track.dropbox['path']
        )

        url = response['url']
        self.redirect(url)
        sync.redis.set(url_key, url)

        # https://www.dropbox.com/developers/reference/api#date-format
        # We don't include %z because of http://bugs.python.org/issue6641
        expires = datetime.strptime(
            response['expires'][:-6], '%a, %d %b %Y %H:%M:%S')
        sync.redis.expire(url_key, (expires - datetime.utcnow()).seconds)
