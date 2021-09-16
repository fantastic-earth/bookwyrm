""" bookwyrm settings and configuration """
# pylint: disable=wildcard-import
# pylint: disable=unused-wildcard-import
from bookwyrm.settings import *

if (socket := env("REDIS_BROKER_SOCKET", None)) is not None:
    CELERY_BROKER_URL = "redis+socket://{}?virtual_host=0".format(socket)
    CELERY_RESULT_BACKEND = CELERY_BROKER_URL
else:
    CELERY_BROKER_URL = "redis://{}:{}/0".format(
        env("REDIS_BROKER_HOST"),
        env("REDIS_BROKER_PORT")
    )
    CELERY_RESULT_BACKEND = CELERY_BROKER_URL

CELERY_DEFAULT_QUEUE = "low_priority"

CELERY_ACCEPT_CONTENT = ["json"]
CELERY_TASK_SERIALIZER = "json"
CELERY_RESULT_SERIALIZER = "json"
FLOWER_PORT = env("FLOWER_PORT", None)

INSTALLED_APPS = INSTALLED_APPS + [
    "celerywyrm",
]

ROOT_URLCONF = "celerywyrm.urls"

WSGI_APPLICATION = "celerywyrm.wsgi.application"
