import logging

import boto3
from botocore.config import Config
from botocore.exceptions import BotoCoreError, ClientError

logger = logging.getLogger(__name__)


def _publish(name: str, value: float, unit: str):
    try:
        cloudwatch = boto3.client(
            "cloudwatch",
            config=Config(
                connect_timeout=2,
                read_timeout=2,
                retries={"total_max_attempts": 1},
            ),
        )
        cloudwatch.put_metric_data(
            Namespace="TodoListAPI",
            MetricData=[{"MetricName": name, "Value": value, "Unit": unit}],
        )
    except (BotoCoreError, ClientError) as error:
        logger.warning("No se pudo publicar %s: %s", name, error)


def record_rds_error():
    _publish("RdsErrors", 1, "Count")


def record_task_read_latency(milliseconds: float):
    _publish("TaskReadLatency", milliseconds, "Milliseconds")