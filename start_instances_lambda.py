import boto3

def lambda_handler(event, context):
    # Indicate the dynamodb table name
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('StopInstanceDBtable')

    instances_to_start = []

    # Read db and retrieve the stopped instance data
    response = table.scan()
    for item in response['Items']:
        instance_id = item['InstanceId']
        instance_name = item['InstanceName']
        region = item['Region']

        ec2_client = boto3.client('ec2', region_name=region)
        instance = ec2_client.describe_instances(InstanceIds=[instance_id])

        if instance['Reservations'][0]['Instances'][0]['State']['Name'] == 'stopped':
            instances_to_start.append((instance_id, instance_name))

    # Start up the stopped instances
    if instances_to_start:
        print("Starting instances:")
        ec2 = boto3.resource('ec2')

        for instance_id, instance_name in instances_to_start:
            print(f"Starting instance: ID={instance_id}, Name={instance_name}")
            ec2.instances.filter(InstanceIds=[instance_id]).start()
    else:
        print("No instances to start.")
