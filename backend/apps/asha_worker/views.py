from rest_framework import generics, status, permissions
from rest_framework.response import Response
from rest_framework_simplejwt.views import TokenObtainPairView
from .models import AshaWorker
from .serializers import AshaWorkerSerializer

from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate

class AshaRegisterView(generics.CreateAPIView):
    queryset = AshaWorker.objects.all()
    serializer_class = AshaWorkerSerializer
    permission_classes = (permissions.AllowAny,)
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        refresh = RefreshToken.for_user(user)
        return Response({
            'user': AshaWorkerSerializer(user).data,
            'token': str(refresh.access_token),
        }, status=status.HTTP_201_CREATED)

class LoginView(generics.GenericAPIView):
    permission_classes = (permissions.AllowAny,)
    serializer_class = AshaWorkerSerializer # Not really used for validation here but good for metadata

    def post(self, request):
        phone_number = request.data.get('phone_number')
        password = request.data.get('password')
        
        user = authenticate(phone_number=phone_number, password=password)
        
        if user:
            refresh = RefreshToken.for_user(user)
            return Response({
                'user': AshaWorkerSerializer(user).data,
                'token': str(refresh.access_token),
            })
        return Response({'error': 'Invalid Credentials'}, status=status.HTTP_401_UNAUTHORIZED)

class AshaProfileView(generics.RetrieveAPIView):
    serializer_class = AshaWorkerSerializer
    
    def get_object(self):
        return self.request.user
