"""
Decorators for Azure Functions logging and telemetry

This module provides decorators to automatically add logging and telemetry
to Azure Functions.
"""

import functools
import time
from typing import Any, Callable, Dict, Optional
import uuid

import azure.functions as func

from .logging_config import get_logger
from .telemetry import track_custom_event, track_custom_metric, track_exception


def log_function_execution(
    function_name: Optional[str] = None,
    track_performance: bool = True,
    track_events: bool = True,
    custom_properties: Optional[Dict[str, str]] = None,
) -> Any:
    """
    Decorator to automatically log function execution with Application Insights

    Args:
        function_name: Override function name for logging
        track_performance: Whether to track execution time
        track_events: Whether to track start/end events
        custom_properties: Additional properties to include in logs

    Returns:
        Decorated function
    """

    def decorator(func_handler: Callable) -> Callable:
        @functools.wraps(func_handler)
        def wrapper(req: func.HttpRequest) -> func.HttpResponse:
            # Generate correlation ID
            correlation_id = str(uuid.uuid4())

            # Get function name
            fn_name = function_name or func_handler.__name__

            # Setup logger with context
            logger = get_logger(
                __name__,
                function_name=fn_name,
                correlation_id=correlation_id,
                custom_properties=custom_properties,
            )

            # Track function start
            start_time = time.time()

            if track_events:
                track_custom_event(
                    "FunctionStarted",
                    properties={
                        "function_name": fn_name,
                        "correlation_id": correlation_id,
                        "method": req.method,
                        "url": req.url,
                        **(custom_properties or {}),
                    },
                )

            logger.info(
                f"Function {fn_name} started - Correlation ID: {correlation_id}"
            )

            try:
                # Execute the function
                result = func_handler(req)

                # Calculate execution time
                execution_time = (
                    time.time() - start_time
                ) * 1000  # Convert to milliseconds

                # Track performance
                if track_performance:
                    track_custom_metric(
                        "FunctionExecutionTime",
                        execution_time,
                        properties={
                            "function_name": fn_name,
                            "correlation_id": correlation_id,
                            "status": "success",
                        },
                    )

                # Track function completion
                if track_events:
                    track_custom_event(
                        "FunctionCompleted",
                        properties={
                            "function_name": fn_name,
                            "correlation_id": correlation_id,
                            "status_code": str(result.status_code),
                            "execution_time_ms": str(execution_time),
                        },
                    )

                logger.info(
                    f"Function {fn_name} completed successfully in {execution_time:.2f}ms - "
                    f"Status: {result.status_code}"
                )

                return result

            except Exception as e:
                # Calculate execution time for failed requests
                execution_time = (time.time() - start_time) * 1000

                # Track exception
                track_exception(
                    e,
                    properties={
                        "function_name": fn_name,
                        "correlation_id": correlation_id,
                        "execution_time_ms": str(execution_time),
                    },
                )

                # Track performance for failed requests
                if track_performance:
                    track_custom_metric(
                        "FunctionExecutionTime",
                        execution_time,
                        properties={
                            "function_name": fn_name,
                            "correlation_id": correlation_id,
                            "status": "error",
                        },
                    )

                # Track function failure
                if track_events:
                    track_custom_event(
                        "FunctionFailed",
                        properties={
                            "function_name": fn_name,
                            "correlation_id": correlation_id,
                            "error_type": type(e).__name__,
                            "error_message": str(e),
                            "execution_time_ms": str(execution_time),
                        },
                    )

                logger.error(
                    f"Function {fn_name} failed after {execution_time:.2f}ms - "
                    f"Error: {type(e).__name__}: {str(e)}"
                )

                # Re-raise the exception
                raise

        return wrapper

    return decorator


def log_dependency_call(
    dependency_name: str, dependency_type: str = "HTTP", target: Optional[str] = None
) -> Any:
    """
    Decorator to log dependency calls

    Args:
        dependency_name: Name of the dependency
        dependency_type: Type of dependency (HTTP, SQL, etc.)
        target: Target of the dependency call

    Returns:
        Decorated function
    """

    def decorator(func_call: Callable) -> Callable:
        @functools.wraps(func_call)
        def wrapper(*args: Any, **kwargs: Any) -> Any:
            logger = get_logger(__name__)
            start_time = time.time()

            try:
                result = func_call(*args, **kwargs)
                duration_ms = (time.time() - start_time) * 1000

                # Track successful dependency
                from .telemetry import track_dependency

                track_dependency(
                    dependency_name,
                    dependency_type,
                    target or "unknown",
                    True,
                    duration_ms,
                )

                logger.info(
                    f"Dependency call successful: {dependency_name} ({duration_ms:.2f}ms)"
                )

                return result

            except Exception as e:
                duration_ms = (time.time() - start_time) * 1000

                # Track failed dependency
                from .telemetry import track_dependency

                track_dependency(
                    dependency_name,
                    dependency_type,
                    target or "unknown",
                    False,
                    duration_ms,
                    properties={"error": str(e)},
                )

                logger.error(
                    f"Dependency call failed: {dependency_name} ({duration_ms:.2f}ms) - "
                    f"Error: {str(e)}"
                )

                raise

        return wrapper

    return decorator


def retry_with_logging(
    max_retries: int = 3, delay_seconds: float = 1.0, backoff_multiplier: float = 2.0
) -> Any:
    """
    Decorator to retry function calls with exponential backoff and logging

    Args:
        max_retries: Maximum number of retry attempts
        delay_seconds: Initial delay between retries
        backoff_multiplier: Multiplier for exponential backoff

    Returns:
        Decorated function
    """

    def decorator(func_call: Callable) -> Callable:
        @functools.wraps(func_call)
        def wrapper(*args: Any, **kwargs: Any) -> Any:
            logger = get_logger(__name__)

            for attempt in range(max_retries + 1):
                try:
                    result = func_call(*args, **kwargs)

                    if attempt > 0:
                        logger.info(f"Function succeeded on attempt {attempt + 1}")
                        track_custom_event(
                            "RetrySucceeded",
                            properties={
                                "function_name": func_call.__name__,
                                "attempt": str(attempt + 1),
                                "max_retries": str(max_retries),
                            },
                        )

                    return result

                except Exception as e:
                    if attempt == max_retries:
                        logger.error(
                            f"Function failed after {max_retries + 1} attempts: {str(e)}"
                        )
                        track_custom_event(
                            "RetryExhausted",
                            properties={
                                "function_name": func_call.__name__,
                                "attempts": str(max_retries + 1),
                                "final_error": str(e),
                            },
                        )
                        raise

                    delay = delay_seconds * (backoff_multiplier**attempt)
                    logger.warning(
                        f"Function failed on attempt {attempt + 1}, retrying in {delay}s: {str(e)}"
                    )

                    track_custom_event(
                        "RetryAttempt",
                        properties={
                            "function_name": func_call.__name__,
                            "attempt": str(attempt + 1),
                            "error": str(e),
                            "next_delay": str(delay),
                        },
                    )

                    time.sleep(delay)

            # This should never be reached, but just in case
            raise RuntimeError("Unexpected end of retry loop")

        return wrapper

    return decorator
