import tornado.web
import tornado.gen

from cloudtunes.services.handlers import ServiceAuthHandler
from cloudtunes.users.models import User
from .client import AsyncLastfmClient
from .models import LastfmAccount


class LastfmAuthHandler(ServiceAuthHandler):

    @tornado.gen.coroutine
    def get(self):
        token = self.get_argument('token', None)
        client = AsyncLastfmClient()
        if not token:
            callback_url = self.get_absolute_url(self.reverse_url(
                'lastfm' if not self.popup else 'lastfm_popup'))
            self.redirect(client.get_auth_url(callback_url))
        else:
            session = yield client.auth.get_session(token=token)
            client.session_key = session['key']

            profile = yield client.user.get_info()

            try:
                user = User.objects.get(lastfm__name=session['name'])
            except User.DoesNotExist:
                if self.current_user:
                    # Connect
                    user = self.current_user
                    user.lastfm = LastfmAccount()
                else:
                    user = User(
                        name=profile.get('realname', ''),
                        lastfm=LastfmAccount()
                    )

            user.lastfm.session_key = session['key']
            profile['subscriber'] = bool(int(profile['subscriber']))
            user.lastfm.update_fields(**profile)

            if not user.picture:
                # noinspection PyUnresolvedReferences
                user.picture = user.lastfm.get_picture()

            if not user.username:
                user.username = user.lastfm.name

            user.save()

            self.service_connected(user)
