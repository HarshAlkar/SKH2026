from rest_framework import serializers
from .models import ChatThread, ChatMessage


class ChatMessageSerializer(serializers.ModelSerializer):
    sender_id = serializers.IntegerField(source='sender.id', read_only=True)
    sender_name = serializers.SerializerMethodField()

    class Meta:
        model = ChatMessage
        fields = ['id', 'thread', 'sender_id', 'sender_name', 'text', 'created_at', 'is_read']
        read_only_fields = ['thread', 'sender_id', 'sender_name', 'created_at', 'is_read']

    def get_sender_name(self, obj):
        return obj.sender.name or obj.sender.username


class ChatThreadSerializer(serializers.ModelSerializer):
    peer_user_id = serializers.SerializerMethodField()
    peer_name = serializers.SerializerMethodField()
    peer_role = serializers.SerializerMethodField()
    peer_phone = serializers.SerializerMethodField()
    last_message = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()

    class Meta:
        model = ChatThread
        fields = [
            'id', 'peer_user_id', 'peer_name', 'peer_role', 'peer_phone',
            'last_message', 'unread_count', 'updated_at', 'created_at',
        ]

    def _peer(self, obj):
        request = self.context.get('request')
        user = getattr(request, 'user', None)
        if user and user.is_authenticated:
            return obj.peer_for(user)
        return obj.user_b

    def get_peer_user_id(self, obj):
        return self._peer(obj).id

    def get_peer_name(self, obj):
        peer = self._peer(obj)
        return peer.name or peer.username

    def get_peer_role(self, obj):
        return self._peer(obj).role

    def get_peer_phone(self, obj):
        return self._peer(obj).phone_number

    def get_last_message(self, obj):
        msg = obj.messages.order_by('-created_at').first()
        if not msg:
            return None
        return ChatMessageSerializer(msg).data

    def get_unread_count(self, obj):
        request = self.context.get('request')
        user = getattr(request, 'user', None)
        if not user or not user.is_authenticated:
            return 0
        return obj.messages.filter(is_read=False).exclude(sender=user).count()
