# Keep services.train_model as a thin wrapper for older entrypoints.
from ai_engine.symptoms.train import train as train_model

__all__ = ["train_model"]
