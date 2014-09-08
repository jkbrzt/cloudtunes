from setuptools import setup


setup(
    version='0.0.1',
    name='cloudtunes',
    entry_points={
        'console_scripts': [
            'cloudtunes-server = cloudtunes.server:main',
            'cloudtunes-worker = cloudtunes.worker:main',
        ],
    },
)
