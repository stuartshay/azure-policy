"""
Mock implementations for testing functions without external dependencies.
"""


def log_function_execution(
    function_name=None, track_performance=True, track_events=True
):
    """Mock decorator that does nothing."""

    def decorator(func):
        return func

    return decorator


def get_logger(name, function_name=None, **kwargs):
    """Mock logger that does nothing."""

    class MockLogger:
        def info(self, *args, **kwargs):
            pass

        def error(self, *args, **kwargs):
            pass

        def warning(self, *args, **kwargs):
            pass

    return MockLogger()


def setup_application_insights():
    """Mock setup function that does nothing."""


def track_custom_event(event_name, properties=None):
    """Mock telemetry function that does nothing."""


def track_custom_metric(metric_name, value, properties=None):
    """Mock telemetry function that does nothing."""
