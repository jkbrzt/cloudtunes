from mongoengine import StringField

from cloudtunes.base.models import DynamicEmbeddedDocument


class YoutubeTrack(DynamicEmbeddedDocument):

    # noinspection PyShadowingBuiltins
    id = StringField(required=True)
