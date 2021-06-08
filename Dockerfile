FROM python:3.9

ENV PYTHONUNBUFFERED 1

RUN mkdir /app /app/static /app/images

WORKDIR /app


COPY pyproject.toml poetry.lock ./
RUN poetry install --no-dev

COPY ./bookwyrm ./celerywyrm ${APP_DIR}/
