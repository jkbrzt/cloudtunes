from __future__ import absolute_import
import json
import logging

import requests
from dropbox.session import DropboxSession
from dropbox.client import DropboxClient
from tornado.httpclient import AsyncHTTPClient, HTTPRequest

from cloudtunes import settings
from cloudtunes.utils import cached_property


class Session(DropboxSession):

    def __init__(self,
                 consumer_key=settings.DROPBOX_API_APP_KEY,
                 consumer_secret=settings.DROPBOX_API_APP_SECRET,
                 access_type=settings.DROPBOX_API_ACCESS_TYPE,
                 locale=None):

        super(Session, self).__init__(
            consumer_key, consumer_secret,
            access_type, locale)


class Client(DropboxClient):

    def __init__(self, session, logger=logging.getLogger(__name__)):
        super(Client, self).__init__(session)
        self.logger = logger

    def get_byte_range(self, path, start, end):
        size = end - start

        self.logger.debug(
            'getting byte range %d:%d (%d) for %s',
            start, end, size, path
        )

        url, params, headers = self.request(
            '/files/%s%s' %
            (self.session.root, path),
            content_server=True
        )

        headers['Range'] = 'bytes=%d-%d' % (start, end)

        resp = requests.get(url, headers=headers)

        self.logger.debug(
            'got resp: status=%s; len=%s',
            resp.status_code, resp.headers['Content-Length']
        )

        return resp.raw.read()

    @cached_property
    def async_client(self):
        return AsyncHTTPClient()

    def _async_request(self, path, callback):
        url, params, headers = self.request(path, method='GET')
        request = HTTPRequest(url=url, method='GET', headers=headers)

        def on_finish(response):
            if response.error is not None:
                response.rethrow()
            callback(json.loads(response.body))

        self.async_client.fetch(request, callback=on_finish)

    def media_async(self, path, callback):
        path = '/media/%s%s' % (self.session.root, path)
        self._async_request(path, callback)

    @classmethod
    def for_account(cls, account):
        sess = Session()
        sess.set_token(account.oauth_token_key,
                       account.oauth_token_secret)
        return cls(sess)
