import json
import logging
import os
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

cloudwatch = boto3.client("cloudwatch")
CPU_THRESHOLD = float(os.environ.get("CPU_THRESHOLD", "80"))


def alarm_name(instance_id):
    return f"ec2-cpu-utilization-{instance_id}"


def create_alarm(instance_id):
    cloudwatch.put_metric_alarm(
        AlarmName=alarm_name(instance_id),
        AlarmDescription=f"CPU utilization > {CPU_THRESHOLD}% for EC2 instance {instance_id}",
        MetricName="CPUUtilization",
        Namespace="AWS/EC2",
        Statistic="Average",
        Dimensions=[{"Name": "InstanceId", "Value": instance_id}],
        Period=300,
        EvaluationPeriods=2,
        Threshold=CPU_THRESHOLD,
        ComparisonOperator="GreaterThanThreshold",
        TreatMissingData="breaching",
    )
    logger.info(f"Created CPU alarm for {instance_id}")


def delete_alarm(instance_id):
    cloudwatch.delete_alarms(AlarmNames=[alarm_name(instance_id)])
    logger.info(f"Deleted CPU alarm for {instance_id}")


def lambda_handler(event, context):
    logger.info(json.dumps(event))
    detail = event.get("detail", {})
    instance_id = detail.get("instance-id")
    state = detail.get("state")

    if not instance_id or not state:
        logger.warning("Missing instance-id or state in event detail")
        return

    if state == "running":
        create_alarm(instance_id)
    elif state == "terminated":
        delete_alarm(instance_id)
    else:
        logger.info(f"Ignoring state: {state}")
