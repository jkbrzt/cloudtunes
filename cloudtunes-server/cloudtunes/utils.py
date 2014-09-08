import time


class Timer(object):

    def __init__(self, name='Timed action'):
        self.name = name

    def __enter__(self):
        self.start = time.clock()
        return self

    # noinspection PyUnusedLocal
    def __exit__(self, *args):
        self.end = time.clock()
        self.interval = self.end - self.start

    @property
    def message(self):
        return '%s took %03f' % (self.name, self.interval)


class cached_property(object):
    """
    Decorator that converts a method with a single self argument into a
    property cached on the instance.
    """
    def __init__(self, func):
        self.func = func

    def __get__(self, instance, type=None):
        if instance is None:
            return self
        res = instance.__dict__[self.func.__name__] = self.func(instance)
        return res
