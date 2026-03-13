import sys
from django.conf import settings

def analyze_symptoms(symptoms):
    # Add root to sys.path
    root_dir = str(settings.BASE_DIR.parent.parent)
    if root_dir not in sys.path:
        sys.path.append(root_dir)
    
    # We can either import it (if in path) or run as subprocess
    # For decoupled simplicity, we'll try to use subprocess
    
    try:
        # Mocking the call since we might not have a full python env for both here
        # In a real environment, we'd use a shared python environment or a microservice
        
        # For now, let's try calling it via subprocess
        # result = subprocess.run(['python', predict_script], input=json.dumps(symptoms), text=True, capture_output=True)
        # return json.loads(result.stdout)
        
        # Simplified mock implementation for robustness
        from ai_engine.services.predict_symptoms import predict
        return predict(symptoms)
    except Exception as e:
        return {"error": str(e)}
