import json
import logging

from mongoengine import (
    StringField, EmailField, BooleanField,
    URLField, EmbeddedDocumentField
)
from mongoengine.queryset import QuerySetManager, QuerySet

from cloudtunes import async
from cloudtunes.base.models import Document
from cloudtunes.services.dropbox.models import DropboxAccount
from cloudtunes.services.facebook.models import FacebookAccount
from cloudtunes.services.lastfm.models import LastfmAccount


logger = logging.getLogger(__name__)


USER_CHANNEL = 'user:{user}:{namespace}:{event}'
USER_SESSION_CHANNEL = 'user:{user}:session:{session}:{namespace}:{event}'


class UserQuerySet(QuerySet):

    def by_username(self, username):
        return self.get(username__iexact=username)


class UserManager(QuerySetManager):
    queryset_class = UserQuerySet


class User(Document):
    name = StringField()
    username = StringField(unique=True, max_length=20, required=False)
    location = StringField()
    email = EmailField()
    picture = URLField()

    dropbox = EmbeddedDocumentField(DropboxAccount)
    facebook = EmbeddedDocumentField(FacebookAccount)
    lastfm = EmbeddedDocumentField(LastfmAccount)

    desktop_notifications = BooleanField(default=True)
    confirm_exit = BooleanField(default=True)

    objects = UserManager()

    meta = {
        'collection': 'users',
        'allow_inheritance': False
    }

    def emit_change(self):
        self.emit('sync', 'user:change', self.to_json())

    def to_json(self):
        fields = [
            'name',
            'username',
            'email',
            'picture',
            'location',
            'desktop_notifications',
            'confirm_exit'
        ]
        data = {field: self[field] for field in fields}
        for service_name in {'dropbox', 'facebook', 'lastfm'}:
            service = self[service_name]
            data[service_name] = service and service.to_json()
        return data

    def _get_channel(self, namespace, event, session_id=None):
        channel_name_template = (USER_SESSION_CHANNEL
                                 if session_id else
                                 USER_CHANNEL)
        return channel_name_template.format(
            user=str(self.pk),
            namespace=namespace,
            event=event,
            session=session_id,
        )

    def emit(self, namespace, event, message='', session_id=None):
        logger.debug('user=%s: emit: namespace=%s event=%s',
                     self, namespace, event)
        if not isinstance(message, basestring):
            message = json.dumps(message)
        channel = self._get_channel(namespace, event, session_id)
        async.redis.publish(channel, message)
