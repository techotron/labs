import boto3
import json
import sys

accessKey = sys.argv[1]
secretKey = sys.argv[2]
region = sys.argv[3]
tableName = sys.argv[4]


mysession = boto3.session.Session(aws_access_key_id=accessKey, aws_secret_access_key=secretKey)

dynamodb = mysession.resource('dynamodb', region_name=region)
table = dynamodb.Table(tableName)

result = table.scan()
jsonOutput = json.dumps(result)

print(jsonOutput)

for item in result['Items']:
    print(item['ComputerName'])



