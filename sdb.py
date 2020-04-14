import boto3
from datetime import datetime


session = boto3.Session(profile_name='example-mfa')
sdb = session.client('sdb', region_name='us-east-1')

def put_attributes(sdb, domain):
    response = sdb.put_attributes(
        DomainName=domain,
        ItemName='last_checkin',
        Attributes=[
            {
                'Name': 'timestamp1',
                'Value': str(datetime.now().timestamp()),
                'Replace': True
            },
        ],
    )
    # print(response)

sdb.delete_domain(
        DomainName='test-domain')
sdb.create_domain(
        DomainName='test-domain')

print(sdb.list_domains())

domain = 'test-domain'

put_attributes(sdb, domain)

response = sdb.select(
    SelectExpression='select timestamp1 from `{0}`'.format(
            domain))
print(response)
print(response['Items'][0]['Attributes'][0]['Value'])
