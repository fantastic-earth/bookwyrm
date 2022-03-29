""" bookwyrm settings and configuration """
# pylint: disable=wildcard-import
# pylint: disable=unused-wildcard-import
from bookwyrm.settings import *

# pylint: disable=line-too-long
if (socket := env("REDIS_BROKER_SOCKET", None)) is not None:
    CELERY_BROKER_URL = "redis+socket://{}?virtual_host={}".format(
        socket,
        env("REDIS_BROKER_DB_INDEX", 0)
    )
    CELERY_RESULT_BACKEND = CELERY_BROKER_URL
else:
    CELERY_BROKER_URL = "redis://{}:{}/{}".format(
        env("REDIS_BROKER_HOST"),
        env("REDIS_BROKER_PORT"),
        env("REDIS_BROKER_DB_INDEX", 0)
    )
    CELERY_RESULT_BACKEND = CELERY_BROKER_URL

CELERY_DEFAULT_QUEUE = "low_priority"
CELERY_CREATE_MISSING_QUEUES = True

CELERY_ACCEPT_CONTENT = ["json"]
CELERY_TASK_SERIALIZER = "json"
CELERY_RESULT_SERIALIZER = "json"

CELERY_BEAT_SCHEDULER = "django_celery_beat.schedulers:DatabaseScheduler"
CELERY_TIMEZONE = env("TIME_ZONE", "UTC")

FLOWER_PORT = env("FLOWER_PORT", None)

INSTALLED_APPS = INSTALLED_APPS + [
    "celerywyrm",
]

ROOT_URLCONF = "celerywyrm.urls"

WSGI_APPLICATION = "celerywyrm.wsgi.application"
