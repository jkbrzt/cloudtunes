import uuid

from cloudtunes.sync import redis


class Session(dict):

    def __init__(self, sid=None):
        super(Session, self).__init__()
        self.sid = sid
        self['user'] = ''
        if not self.sid:
            self.set_sid()

    @property
    def key(self):
        return Session.get_key(self.sid)

    def load(self):
        self.update(redis.hgetall(self.key))

    def save(self):
        redis.hmset(self.key, self)
        Session.set_ttl(self.sid)

    def set_sid(self):
        self.sid = str(uuid.uuid4())

    @staticmethod
    def set_ttl(sid):
        redis.expire(Session.get_key(sid), 60 * 60 * 24 * 30)

    @staticmethod
    def get_key(sid):
        return 'session:%s' % sid
