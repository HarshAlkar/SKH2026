from rest_framework import serializers, viewsets, status
from rest_framework.response import Response
from rest_framework.decorators import action
from django.contrib.auth import authenticate
from .models import User

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'role', 'phone', 'first_name', 'last_name']

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'role', 'phone']
    
    def create(self, validated_data):
        user = User.objects.create_user(**validated_data)
        return user

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer

    @action(detail=False, methods=['post'], url_path='register')
    def register(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['post'], url_path='login')
    def login(self, request):
        username = request.data.get('username')
        password = request.data.get('password')
        user = authenticate(username=username, password=password)
        if user:
            # Simple mockup: in real apps, use JWT
            return Response({
                "token": "mock-jwt-token",
                "user": UserSerializer(user).data
            })
        return Response({"error": "Invalid credentials"}, status=status.HTTP_401_UNAUTHORIZED)
