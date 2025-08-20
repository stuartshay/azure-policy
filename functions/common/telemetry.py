"""
Telemetry helpers for Application Insights

This module provides helper functions for tracking custom events and metrics
in Application Insights.
"""

from datetime import datetime, timezone
import logging
from typing import Any, Dict, Optional

try:
    from opencensus.trace import (  # pyright: ignore [reportMissingImports]
        execution_context,
    )
    from opencensus.trace.span import Span  # pyright: ignore [reportMissingImports]

    OPENCENSUS_AVAILABLE = True
except ImportError:
    OPENCENSUS_AVAILABLE = False
    execution_context = None
    Span = None

from .logging_config import get_tracer


def track_custom_event(
    name: str,
    properties: Optional[Dict[str, str]] = None,
    measurements: Optional[Dict[str, float]] = None,
) -> None:
    """
    Track a custom event in Application Insights

    Args:
        name: Event name
        properties: Custom properties (string values)
        measurements: Custom measurements (numeric values)
    """
    logger = logging.getLogger(__name__)

    # Create event data
    event_data = {
        "event_name": name,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }

    if properties:
        event_data.update(properties)

    if measurements:
        for k, v in measurements.items():
            event_data[f"measurement_{k}"] = str(v)

    # Log the event
    logger.info(f"Custom Event: {name}", extra={"custom_event": event_data})

    # Add to current span if available
    if OPENCENSUS_AVAILABLE and execution_context:
        tracer = get_tracer()
        if tracer:
            current_span = execution_context.get_current_span()
            if current_span:
                current_span.add_attribute("custom_event", name)
                if properties:
                    for key, value in properties.items():
                        current_span.add_attribute(f"event_{key}", value)


def track_custom_metric(
    name: str, value: float, properties: Optional[Dict[str, str]] = None
) -> None:
    """
    Track a custom metric in Application Insights

    Args:
        name: Metric name
        value: Metric value
        properties: Custom properties
    """
    logger = logging.getLogger(__name__)

    # Create metric data
    metric_data = {
        "metric_name": name,
        "metric_value": value,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }

    if properties:
        metric_data.update(properties)

    # Log the metric
    logger.info(
        f"Custom Metric: {name} = {value}", extra={"custom_metric": metric_data}
    )

    # Add to current span if available
    if OPENCENSUS_AVAILABLE and execution_context:
        tracer = get_tracer()
        if tracer:
            current_span = execution_context.get_current_span()
            if current_span:
                current_span.add_attribute(f"metric_{name}", str(value))
                if properties:
                    for key, prop_value in properties.items():
                        current_span.add_attribute(f"metric_{key}", prop_value)


def track_dependency(  # pylint: disable=too-many-positional-arguments
    name: str,
    dependency_type: str,
    target: str,
    success: bool,
    duration_ms: float,
    properties: Optional[Dict[str, str]] = None,
) -> None:
    """
    Track a dependency call in Application Insights

    Args:
        name: Dependency name
        dependency_type: Type of dependency (HTTP, SQL, etc.)
        target: Target of the dependency call
        success: Whether the call was successful
        duration_ms: Duration in milliseconds
        properties: Custom properties
    """
    logger = logging.getLogger(__name__)

    # Create dependency data
    dependency_data = {
        "dependency_name": name,
        "dependency_type": dependency_type,
        "target": target,
        "success": success,
        "duration_ms": duration_ms,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }

    if properties:
        dependency_data.update(properties)

    # Log the dependency
    log_level = logging.INFO if success else logging.WARNING
    logger.log(
        log_level,
        f"Dependency: {name} -> {target} ({duration_ms}ms) - {'Success' if success else 'Failed'}",
        extra={"dependency": dependency_data},
    )


def track_exception(
    exception: Exception,
    properties: Optional[Dict[str, str]] = None,
    measurements: Optional[Dict[str, float]] = None,
) -> None:
    """
    Track an exception in Application Insights

    Args:
        exception: The exception to track
        properties: Custom properties
        measurements: Custom measurements
    """
    logger = logging.getLogger(__name__)

    # Create exception data
    exception_data = {
        "exception_type": type(exception).__name__,
        "exception_message": str(exception),
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }

    if properties:
        exception_data.update(properties)

    if measurements:
        for k, v in measurements.items():
            exception_data[f"measurement_{k}"] = str(v)

    # Log the exception
    logger.exception(
        f"Exception tracked: {type(exception).__name__}: {str(exception)}",
        extra={"tracked_exception": exception_data},
    )


def create_span(name: str, properties: Optional[Dict[str, str]] = None) -> Any:
    """
    Create a new span for tracing

    Args:
        name: Span name
        properties: Custom properties to add to the span

    Returns:
        Span context manager or None if tracing is not available
    """
    if not OPENCENSUS_AVAILABLE:
        return None

    tracer = get_tracer()
    if not tracer:
        return None

    span = tracer.start_span(name)

    if properties:
        for key, value in properties.items():
            span.add_attribute(key, value)

    return span
