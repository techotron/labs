import boto3
import json
import sys
import socket
from dns import resolver

accessKey = sys.argv[1]
secretKey = sys.argv[2]
region = sys.argv[3]
tableName = sys.argv[4]

computerNames = ['peterw-2620','eddys-3620','joeb-3620','martinl-3620','pc30.rekoop.local']

mysession = boto3.session.Session(aws_access_key_id=accessKey, aws_secret_access_key=secretKey)

dynamodb = mysession.resource('dynamodb', region_name=region)
table = dynamodb.Table(tableName)
resolver = resolver.Resolver()
resolver.nameservers = ['10.146.1.8']

result = table.scan()
jsonOutput = json.dumps(result)

for computer in computerNames:
    try:
        ip = socket.gethostbyname(computer)
    except:
        answers = resolver.query(computer)
        for rdata in answers:
            ip = (rdata.address)

    if computer == 'eddys-3620':
        answers = resolver.query(computer)
        for rdata in answers:
            ip = (rdata.address)

    table.put_item(Item={
        'ComputerName': '%s' % computer,
        'IP': '%s' % ip
    })



print(jsonOutput)

for item in result['Items']:
    print(item['ComputerName'])

