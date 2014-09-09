import os
import re

from fabric import colors
from fabric.api import task
from fabric.api import local
from fabric.api import env
from fabric.api import run
from fabric.api import cd


env.hosts = ['cloudtun.es']
env.user = 'cloudtunes'
env.key_filename = '~/.ssh/id_dsa'

GITHUB = 'git@github.com:jakubroztocil/cloudtunes.git'

ROOT = '~'
CODE_ROOT = '%s/cloudtunes-webapp' % ROOT


BUILD_DIR = os.path.dirname(__file__) + '/build/production'
REV_RE = re.compile('(?<=\.css)|(?<=\.js)')
BUILD_COMMIT_MESSAGE = 'Built for deployment.'


@task
def bootstrap():
    print(colors.cyan('Bootstrapping...', bold=True))
    run('rm -rf %s' % CODE_ROOT)
    run('git clone %s %s' % (GITHUB, CODE_ROOT))


@task
def git_pull():
    with cd(CODE_ROOT):
        run('git pull')


def update_html():

    last_commit_rev = local('git rev-parse HEAD', capture=True)
    print(colors.cyan('Updating index.html...', bold=True))
    with open(BUILD_DIR + '/index.html', 'r+w') as f:
        html = f.read()
        html = REV_RE.sub('?' + last_commit_rev, html)
        f.seek(0)
        f.write(html)


@task
def build():
    print(colors.cyan('Compiling...', bold=True))
    local('rm -rf ' + BUILD_DIR)
    local('brunch build --production --config=config-dist.coffee')
    update_html()

@task
def deploy():
    """Deploy code and schema changes to production"""

    local('git diff --exit-code')  # Must be clean.

    last_commit_message = local('git log --format=%B -n 1', capture=True)

    if last_commit_message != BUILD_COMMIT_MESSAGE:

        build()
        print(colors.cyan('Committing...', bold=True))
        # Can exit 1 with no diff; it's ok
        os.system('git add . && git commit -am "%s"' % BUILD_COMMIT_MESSAGE)
        print(colors.cyan('Pushing...', bold=True))

        local('git push')

    print(colors.cyan('Deploying...', bold=True))
    with cd(CODE_ROOT):
        run('git pull')

