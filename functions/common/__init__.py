"""
Common utilities for Azure Functions

This package provides shared functionality across all Azure Functions including:
- Application Insights logging configuration
- Telemetry helpers
- Decorators for automatic instrumentation
"""

__version__ = "1.0.0"
__author__ = "Azure Policy Team"

from .decorators import log_function_execution
from .logging_config import get_logger, setup_application_insights
from .telemetry import track_custom_event, track_custom_metric

__all__ = [
    "get_logger",
    "setup_application_insights",
    "track_custom_event",
    "track_custom_metric",
    "log_function_execution",
]
