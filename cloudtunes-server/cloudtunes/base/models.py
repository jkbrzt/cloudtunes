import mongoengine


class CloudTunesDocumentMixin(object):

    def update_fields(self, **data):
        for key, value in data.items():
            setattr(self, key, value)


class EmbeddedDocument(mongoengine.EmbeddedDocument,
                       CloudTunesDocumentMixin):
    meta = {
        'abstract': True,
    }


class DynamicDocument(mongoengine.DynamicDocument,
                      CloudTunesDocumentMixin):
    meta = {
        'abstract': True,
    }


class DynamicEmbeddedDocument(mongoengine.DynamicEmbeddedDocument,
                              CloudTunesDocumentMixin):
    meta = {
        'abstract': True,
    }


class Document(mongoengine.Document, CloudTunesDocumentMixin):

    meta = {
        'abstract': True,
    }

    def __unicode__(self):
        return str(self.pk)

    # Fix PyCharm inspections:
    class _DummyQuerySet(mongoengine.queryset.QuerySet):
        #noinspection PyMissingConstructor
        def __init__(self):
            pass

    objects = _DummyQuerySet()
    DoesNotExist = Exception

    del _DummyQuerySet, objects

