# Definition example: 

´yaml
name: "DailyReportingJob"
definition_path: "state_machines/daily-job-definition.json"
schedule_expression: "cron(0 2 * * ? *)" # Runs every day at 2 AM UTC
´

´yaml
name: "S3ObjectProcessor"
definition_path: "state_machines/s3-processor-definition.json"
event_pattern: |
  {
    "source": ["aws.s3"],
    "detail-type": ["Object Created"],
    "detail": {
      "bucket": {
        "name": ["my-source-data-bucket"]
      }
    }
  }
´

