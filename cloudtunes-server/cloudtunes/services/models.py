from mongoengine import IntField

from cloudtunes.base.models import EmbeddedDocument


class ServiceAccount(EmbeddedDocument):

    meta = {
        'abstract': True,
    }

    id = IntField()

    service_name = None

    def get_username(self):
        raise NotImplementedError()

    def get_picture(self):
        raise NotImplementedError()

    def get_url(self):
        raise NotImplementedError()

    def to_json(self):
        return {
            'name': self.service_name,
            'username': self.get_username(),
            'url': self.get_url(),
            'picture': self.get_picture()
        }
