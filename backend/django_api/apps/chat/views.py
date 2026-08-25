from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db.models import Q
from django.utils import timezone
from apps.users.models import User
from .models import ChatThread, ChatMessage
from .serializers import ChatThreadSerializer, ChatMessageSerializer

ALLOWED_PEERS = {
    'user': {'doctor', 'asha_worker'},
    'doctor': {'user', 'asha_worker'},
    'asha_worker': {'user', 'doctor'},
}


def _ordered_ids(id1, id2):
    return (id1, id2) if id1 < id2 else (id2, id1)


class ChatThreadViewSet(viewsets.ViewSet):
    permission_classes = [permissions.IsAuthenticated]

    def list(self, request):
        user = request.user
        threads = (
            ChatThread.objects.filter(Q(user_a=user) | Q(user_b=user))
            .select_related('user_a', 'user_b')
            .order_by('-updated_at')
        )
        serializer = ChatThreadSerializer(threads, many=True, context={'request': request})
        return Response(serializer.data)

    @action(detail=False, methods=['post'], url_path='open')
    def open_thread(self, request):
        peer_id = request.data.get('peer_user_id')
        if not peer_id:
            return Response(
                {'error': 'peer_user_id is required'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        try:
            peer = User.objects.get(pk=peer_id)
        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

        user = request.user
        if peer.id == user.id:
            return Response(
                {'error': 'Cannot chat with yourself'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        allowed = ALLOWED_PEERS.get(user.role, set())
        if peer.role not in allowed:
            return Response(
                {'error': 'Chat is not allowed between these roles'},
                status=status.HTTP_403_FORBIDDEN,
            )

        a_id, b_id = _ordered_ids(user.id, peer.id)
        thread, _ = ChatThread.objects.get_or_create(user_a_id=a_id, user_b_id=b_id)
        serializer = ChatThreadSerializer(thread, context={'request': request})
        return Response(serializer.data, status=status.HTTP_200_OK)

    @action(detail=True, methods=['get', 'post'], url_path='messages')
    def messages(self, request, pk=None):
        user = request.user
        try:
            thread = ChatThread.objects.get(
                Q(pk=pk) & (Q(user_a=user) | Q(user_b=user))
            )
        except ChatThread.DoesNotExist:
            return Response({'error': 'Thread not found'}, status=status.HTTP_404_NOT_FOUND)

        if request.method == 'GET':
            qs = thread.messages.select_related('sender').order_by('created_at')
            thread.messages.filter(is_read=False).exclude(sender=user).update(is_read=True)
            serializer = ChatMessageSerializer(qs, many=True)
            return Response(serializer.data)

        text = (request.data.get('text') or '').strip()
        if not text:
            return Response({'error': 'text is required'}, status=status.HTTP_400_BAD_REQUEST)

        message = ChatMessage.objects.create(thread=thread, sender=user, text=text)
        thread.updated_at = timezone.now()
        thread.save(update_fields=['updated_at'])
        serializer = ChatMessageSerializer(message)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
