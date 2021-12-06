# Generated by Django 3.2.5 on 2021-11-15 18:22

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("bookwyrm", "0116_auto_20211114_1734"),
    ]

    operations = [
        migrations.AlterField(
            model_name="user",
            name="preferred_language",
            field=models.CharField(
                blank=True,
                choices=[
                    ("en-us", "English"),
                    ("de-de", "Deutsch (German)"),
                    ("es-es", "Español (Spanish)"),
                    ("fr-fr", "Français (French)"),
                    ("lt-lt", "lietuvių (Lithuanian)"),
                    ("pt-br", "Português - Brasil (Brazilian Portuguese)"),
                    ("zh-hans", "简体中文 (Simplified Chinese)"),
                    ("zh-hant", "繁體中文 (Traditional Chinese)"),
                ],
                max_length=255,
                null=True,
            ),
        ),
    ]
