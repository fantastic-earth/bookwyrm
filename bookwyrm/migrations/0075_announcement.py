# Generated by Django 3.2 on 2021-05-19 20:58

import bookwyrm.models.fields
from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ("bookwyrm", "0074_auto_20210511_1829"),
    ]

    operations = [
        migrations.CreateModel(
            name="Announcement",
            fields=[
                (
                    "id",
                    models.AutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("created_date", models.DateTimeField(auto_now_add=True)),
                ("updated_date", models.DateTimeField(auto_now=True)),
                (
                    "remote_id",
                    bookwyrm.models.fields.RemoteIdField(
                        max_length=255,
                        null=True,
                        validators=[bookwyrm.models.fields.validate_remote_id],
                    ),
                ),
                ("name", models.CharField(max_length=255)),
                ("preview", models.CharField(max_length=255)),
                ("content", models.TextField()),
                ("event_date", models.DateTimeField(blank=True, null=True)),
                ("start_date", models.DateTimeField(blank=True, null=True)),
                ("end_date", models.DateTimeField(blank=True, null=True)),
                ("active", models.BooleanField(default=True)),
                (
                    "user",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.PROTECT,
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
            ],
            options={
                "abstract": False,
            },
        ),
    ]
