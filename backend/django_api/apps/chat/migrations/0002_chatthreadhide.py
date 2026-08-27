from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('chat', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='ChatThreadHide',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('hidden_at', models.DateTimeField(auto_now_add=True)),
                ('thread', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='hides',
                    to='chat.chatthread',
                )),
                ('user', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='hidden_chat_threads',
                    to=settings.AUTH_USER_MODEL,
                )),
            ],
        ),
        migrations.AddConstraint(
            model_name='chatthreadhide',
            constraint=models.UniqueConstraint(fields=('thread', 'user'), name='unique_hidden_chat_thread'),
        ),
    ]
