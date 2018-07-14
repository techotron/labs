from __future__ import print_function # Python 2/3 compatibility
import boto3
import sys

region = sys.argv[1]
tableName = sys.argv[2]
tenantName = sys.argv[3]
accessKey = sys.argv[4]
secretKey = sys.argv[5]

mysession = boto3.session.Session(aws_access_key_id=accessKey, aws_secret_access_key=secretKey)

dynamodb = mysession.resource('dynamodb', region_name=region)
table = dynamodb.Table(tableName)

table.put_item(Item={
    'itemName()': '%s|CloudSyncJob' % (tenantName),
    'cron': '0 0/5 * * * ?',
    'runNow': '1',
    'task': 'CloudSyncJob',
    'tenant': tenantName})


