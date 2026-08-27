from django.contrib import admin
from .models import ChatThread, ChatMessage, ChatThreadHide


@admin.register(ChatThread)
class ChatThreadAdmin(admin.ModelAdmin):
    list_display = ('id', 'user_a', 'user_b', 'updated_at')
    search_fields = ('user_a__name', 'user_b__name')


@admin.register(ChatMessage)
class ChatMessageAdmin(admin.ModelAdmin):
    list_display = ('id', 'thread', 'sender', 'created_at', 'is_read')
    search_fields = ('text', 'sender__name')


@admin.register(ChatThreadHide)
class ChatThreadHideAdmin(admin.ModelAdmin):
    list_display = ('id', 'thread', 'user', 'hidden_at')
    search_fields = ('user__name',)
