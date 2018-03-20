from fabric import colors
from fabric.api import task
from fabric.api import env
from fabric.api import run
from fabric.api import cd
from fabric.api import prefix


env.hosts = ['cloudtun.es']
env.user = 'cloudtunes'
env.key_filename = '~/.ssh/id_dsa'


GITHUB = 'git@github.com:jakubroztocil/cloudtunes.git'
ROOT = '~'
CODE_ROOT = '%s/cloudtunes' % ROOT
VIRTUALENV = '%s/virtualenv' % ROOT
VIRTUALENV_ACTIVATE = '. %s/bin/activate' % VIRTUALENV
LOCAL_SETTINGS = '%s/cloudtunes/settings/local.py' % CODE_ROOT


@task
def bootstrap():
    """
    First follow production/README.rst

    """
    print(colors.cyan('Bootstrapping...', bold=True))
    run('rm -rf %s %s' % (CODE_ROOT, VIRTUALENV))
    run('git clone %s %s' % (GITHUB, CODE_ROOT))
    run('virtualenv --no-site-packages --prompt="(cloudtunes)" '
        '%s' % VIRTUALENV)
    run(
        'if ! grep bin/activate ~/.bashrc; '
        'then echo ". ~/virtualenv/bin/activate &>/dev/null" >> ~/.bashrc; fi'
    )
    with cd(CODE_ROOT):
        run('echo "from .production import *" > %s' % LOCAL_SETTINGS)
    install_requirements()


@task
def git_pull():
    with cd(CODE_ROOT):
        run('git pull')


@task
def install_requirements():
    print(colors.cyan('Installing requirements...', bold=True))
    with prefix(VIRTUALENV_ACTIVATE), cd(CODE_ROOT):
        run('pip install -U -r requirements.txt')
        run('pip install -e .')


@task
def deploy():
    """Deploy code to production"""
    print(colors.cyan('Deploying...', bold=True))
    with cd(CODE_ROOT):
        run('git pull')
    install_requirements()
    with cd(CODE_ROOT):
            run(r'find . -name "*.pyc" -delete')
            restart()


@task
def restart():
    run('supervisorctl restart cloudtunes-worker')
    run('supervisorctl restart cloudtunes-server:*')
