"""
Application Insights logging configuration for Azure Functions

This module provides centralized logging configuration with Application Insights integration
for both local development and production environments.
"""

from datetime import datetime, timezone
import logging
import os
import sys
from typing import Any, Dict, MutableMapping, Optional, Tuple, Union

try:
    from opencensus.ext.azure.log_exporter import (  # pyright: ignore [reportMissingImports]
        AzureLogHandler,
    )
    from opencensus.ext.azure.trace_exporter import (  # pyright: ignore [reportMissingImports]
        AzureExporter,
    )
    from opencensus.trace.samplers import (  # pyright: ignore [reportMissingImports]
        ProbabilitySampler,
    )
    from opencensus.trace.tracer import Tracer  # pyright: ignore [reportMissingImports]

    OPENCENSUS_AVAILABLE = True
except ImportError:
    OPENCENSUS_AVAILABLE = False
    AzureLogHandler = None
    AzureExporter = None
    Tracer = None
    ProbabilitySampler = None

# Global tracer instance
_tracer: Optional[Any] = None
_application_insights_configured = False


class ApplicationInsightsFormatter(logging.Formatter):
    """Custom formatter for Application Insights with structured logging"""

    def format(self, record: logging.LogRecord) -> str:
        """Format log record with additional context"""
        # Add timestamp in ISO format
        record.timestamp = datetime.now(timezone.utc).isoformat()

        # Add function context if available
        if hasattr(record, "function_name"):
            setattr(record, "function_context", f"[{getattr(record, 'function_name')}]")
        else:
            setattr(record, "function_context", "")

        # Add correlation ID if available
        if hasattr(record, "correlation_id"):
            setattr(
                record, "correlation_context", f"[{getattr(record, 'correlation_id')}]"
            )
        else:
            setattr(record, "correlation_context", "")

        return super().format(record)


def setup_application_insights(
    connection_string: Optional[str] = None,
    sampling_rate: float = 1.0,
    log_level: str = "INFO",
) -> bool:
    """
    Setup Application Insights logging and tracing

    Args:
        connection_string: Application Insights connection string
        sampling_rate: Sampling rate for telemetry (0.0 to 1.0)
        log_level: Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL)

    Returns:
        bool: True if Application Insights was configured successfully
    """
    global _tracer, _application_insights_configured

    if _application_insights_configured:
        return True

    # Get connection string from parameter or environment
    conn_str = connection_string or os.getenv("APPLICATIONINSIGHTS_CONNECTION_STRING")

    if not conn_str:
        logging.warning(
            "Application Insights connection string not found. Using console logging only."
        )
        return False

    if not OPENCENSUS_AVAILABLE:
        logging.warning(
            "OpenCensus Azure extensions not available. Install 'opencensus-ext-azure' package."
        )
        return False

    try:
        # Setup tracer for distributed tracing
        sampler = ProbabilitySampler(rate=sampling_rate)
        exporter = AzureExporter(connection_string=conn_str)
        _tracer = Tracer(exporter=exporter, sampler=sampler)

        # Configure root logger
        root_logger = logging.getLogger()
        root_logger.setLevel(getattr(logging, log_level.upper()))

        # Add Azure Log Handler
        azure_handler = AzureLogHandler(connection_string=conn_str)
        azure_handler.setLevel(getattr(logging, log_level.upper()))

        # Set custom formatter
        formatter = ApplicationInsightsFormatter(
            "%(timestamp)s - %(name)s - %(levelname)s - %(function_context)s%(correlation_context)s %(message)s"
        )
        azure_handler.setFormatter(formatter)

        # Add handler to root logger
        root_logger.addHandler(azure_handler)

        _application_insights_configured = True
        logging.info("Application Insights logging configured successfully")
        return True

    except Exception as e:
        logging.error(f"Failed to configure Application Insights: {str(e)}")
        return False


def get_logger(
    name: str,
    function_name: Optional[str] = None,
    correlation_id: Optional[str] = None,
    custom_properties: Optional[Dict[str, Any]] = None,
) -> Union[logging.Logger, logging.LoggerAdapter]:
    """
    Get a configured logger with optional context

    Args:
        name: Logger name (typically __name__)
        function_name: Azure Function name for context
        correlation_id: Correlation ID for request tracking
        custom_properties: Additional properties to include in logs

    Returns:
        logging.Logger: Configured logger instance
    """
    logger = logging.getLogger(name)

    # Ensure console handler exists for local development
    if not any(isinstance(h, logging.StreamHandler) for h in logger.handlers):
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(logging.INFO)

        # Console formatter
        console_formatter = logging.Formatter(
            "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
        )
        console_handler.setFormatter(console_formatter)
        logger.addHandler(console_handler)

    # Add context to logger if provided
    if function_name or correlation_id or custom_properties:
        adapted_logger = LoggerAdapter(
            logger, function_name, correlation_id, custom_properties
        )
        return adapted_logger

    return logger


class LoggerAdapter(logging.LoggerAdapter):
    """Logger adapter to add context to log records"""

    def __init__(
        self,
        logger: logging.Logger,
        function_name: Optional[str] = None,
        correlation_id: Optional[str] = None,
        custom_properties: Optional[Dict[str, Any]] = None,
    ):
        self.function_name = function_name
        self.correlation_id = correlation_id
        self.custom_properties = custom_properties or {}
        super().__init__(logger, {})

    def process(
        self, msg: Any, kwargs: MutableMapping[str, Any]
    ) -> Tuple[Any, MutableMapping[str, Any]]:
        """Process log record to add context"""
        # Add function context
        if self.function_name:
            kwargs.setdefault("extra", {})["function_name"] = self.function_name

        # Add correlation ID
        if self.correlation_id:
            kwargs.setdefault("extra", {})["correlation_id"] = self.correlation_id

        # Add custom properties
        if self.custom_properties:
            kwargs.setdefault("extra", {}).update(self.custom_properties)

        return msg, kwargs


def get_tracer() -> Optional[Any]:
    """Get the global tracer instance"""
    return _tracer


def is_application_insights_configured() -> bool:
    """Check if Application Insights is configured"""
    return _application_insights_configured


# Auto-configure Application Insights on import if connection string is available
def _auto_configure() -> None:
    """Auto-configure Application Insights if environment variables are set"""
    connection_string = os.getenv("APPLICATIONINSIGHTS_CONNECTION_STRING")
    if connection_string:
        sampling_rate = (
            float(os.getenv("APPLICATIONINSIGHTS_SAMPLING_PERCENTAGE", "100")) / 100
        )
        log_level = os.getenv("LOGGING_LEVEL", "INFO")
        setup_application_insights(connection_string, sampling_rate, log_level)


# Auto-configure on module import
_auto_configure()
