import tornado.web
import tornado.auth

from cloudtunes.users.models import User
from cloudtunes.services.handlers import ServiceAuthHandler
from cloudtunes import settings
from .models import FacebookAccount
from .sync import sync_account


class FacebookHandler(ServiceAuthHandler, tornado.auth.FacebookGraphMixin):

    @tornado.web.asynchronous
    def get(self):

        redirect_url = self.get_absolute_url('facebook')

        if self.popup:
            redirect_url += '?popup=1'

        if self.get_argument('code', None):
            self.get_authenticated_user(
                redirect_uri=redirect_url,
                client_id=settings.FACEBOOK_APP_ID,
                client_secret=settings.FACEBOOK_APP_SECRET,
                code=self.get_argument('code'),
                callback=self._on_login
            )
        else:
            params = {
                'scope': ','.join(settings.FACEBOOK_PERMISSIONS),
                'redirect_uri': redirect_url,
            }
            if self.popup:
                params['display'] = 'popup'

            self.authorize_redirect(
                redirect_uri=redirect_url,
                client_id=settings.FACEBOOK_APP_ID,
                extra_params=params
            )

    def _on_login(self, fb_data):

        if fb_data:
            # TODO: drop FB usernames (deprecated for versions v2.0 and higher)
            # https://github.com/jakubroztocil/cloudtunes/issues/3

            # HACK: work around removed FB usernames
            fb_data['username'] = fb_data['id']

        try:
            user = User.objects.get(facebook__id=fb_data['id'])
        except User.DoesNotExist:
            if self.current_user:
                # Connect
                user = self.current_user
                user.facebook = FacebookAccount()
            else:
                # Sign up
                user = User(
                    name=' '.join([fb_data.get('first_name'),
                                   fb_data.get('last_name')]),
                    facebook=FacebookAccount()
                )

        user.facebook.update_fields(**fb_data)

        if not user.picture:
            user.picture = user.facebook.get_picture()
        if not user.email:
            user.email = user.facebook.email
        if not user.username and 'username' in fb_data:
            max_length = User._fields['username'].max_length
            username = fb_data.get('username', '')[:max_length]
            if (username and not
                    User.objects.filter(username__iexact=username).count()):
                user.username = username
        if not user.location:
            user.location = fb_data.get('location', {}).get('name', '')

        user.save()

        sync_account.delay(user.facebook.id)
        self.service_connected(user)

