from django.db import models
from django.conf import settings


class ChatThread(models.Model):
    user_a = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='chat_threads_a',
    )
    user_b = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='chat_threads_b',
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=['user_a', 'user_b'], name='unique_chat_pair'),
            models.CheckConstraint(
                condition=models.Q(user_a_id__lt=models.F('user_b_id')),
                name='chat_user_order',
            ),
        ]
        ordering = ['-updated_at']

    def __str__(self):
        return f"Chat {self.user_a_id} ↔ {self.user_b_id}"

    def peer_for(self, user):
        return self.user_b if self.user_a_id == user.id else self.user_a


class ChatMessage(models.Model):
    thread = models.ForeignKey(
        ChatThread,
        on_delete=models.CASCADE,
        related_name='messages',
    )
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='chat_messages',
    )
    text = models.TextField(blank=True)
    image = models.ImageField(upload_to='chat_images/', blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    is_read = models.BooleanField(default=False)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f"Message {self.id} in thread {self.thread_id}"


class ChatThreadHide(models.Model):
    thread = models.ForeignKey(
        ChatThread,
        on_delete=models.CASCADE,
        related_name='hides',
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='hidden_chat_threads',
    )
    hidden_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=['thread', 'user'],
                name='unique_hidden_chat_thread',
            ),
        ]

    def __str__(self):
        return f"Hide thread {self.thread_id} for user {self.user_id}"
