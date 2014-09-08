from rest_framework import serializers

from cloudtunes.models import User, Track, Playlist


class ServiceAccountSerializer(serializers.ModelSerializer):
    name = serializers.Field('service_name')
    username = serializers.Field('get_username')
    url = serializers.Field('get_url')
    picture = serializers.Field('get_picture')


class UserSerializer(serializers.ModelSerializer):

    facebook = ServiceAccountSerializer(read_only=True)
    lastfm = ServiceAccountSerializer(read_only=True)
    dropbox = ServiceAccountSerializer(read_only=True)

    class Meta:
        model = User
        fields = [
            'name',
            'username',
            'email',
            'picture',
            'location',
            'desktop_notifications',
            'confirm_exit',
            'facebook',
            'lastfm',
            'dropbox',
        ]


class TrackSerializer(serializers.ModelSerializer):

    class Meta:
        model = Track
        fields = [
            'id',
            'title',
            'artist',
            'album',
            'number',
            'source',
            'source_id',
            'mbid',
            'artist_mbid',
            'album_mbid',
        ]


class PlaylistSerializer(serializers.ModelSerializer):

    tracks = serializers.PrimaryKeyRelatedField()

    class Meta:
        model = Playlist
        fields = [
            'id',
            'name',
            'collaborative'
            'tracks'
        ]
