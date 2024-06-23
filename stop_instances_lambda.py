import boto3
from datetime import datetime, timezone

def save_to_dynamodb(instance_id, instance_name, region):
    # Indicate the dynamodb table name
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('StopInstanceDBtable')

    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")

    # Save data into db
    table.put_item(
        Item={
            'InstanceId': instance_id,
            'InstanceName': instance_name,
            'Region': region,
            'Timestamp': timestamp
        }
    )

def lambda_handler(event, context):
   
    regions_to_check = ['us-east-1'] 

    # If no specific region indicated, check all region
    if not regions_to_check:
        ec2_client = boto3.client('ec2')
        regions_response = ec2_client.describe_regions()
        regions_list = regions_response.get('Regions', [])

        regions_to_check = [region['RegionName'] for region in regions_list]

    print(f'Region that contain running instances:{regions_to_check}')

    for region in regions_to_check:
        print(f'Checking region:{region}')

        # Filter for those instances that are running
        ec2_resource = boto3.resource('ec2', region_name = region)
        running_filter = {'Name':'instance-state-name', 'Values':['running']}
        instances = ec2_resource.instances.filter(Filters=[running_filter]) 
        
        # Loop thru all the running instances
        for instance in instances:
            env_tag_value = None
            stop_tag_value = None
            name_tag_value = '-'

            if instance.tags == None: # If instance does not contain any tags, stop the instance
                instance.stop()
                save_to_dynamodb(instance.id, name_tag_value, region)
                print(f'Instance stopped: ID={instance.id}, Name={name_tag_value}')
            else:
                for tag in instance.tags:
                    if tag['Key'] == 'env':
                        env_tag_value = tag['Value']
                    elif tag['Key'] == 'autostop':
                        stop_tag_value = tag['Value']
                    elif tag['Key'] == 'Name':
                        name_tag_value = tag['Value']  

                if env_tag_value == 'dev': # Stop instance that are only in 'dev' environment and those without auto-stop tag or auto-stop as true
                    if stop_tag_value == 'true'or stop_tag_value == None:
                        instance.stop()
                        save_to_dynamodb(instance.id, name_tag_value, region)
                        print(f"Instance stopped: ID={instance.id}, Name={name_tag_value}")
        
        print(f'{region} checked')
    print('Completed, no other instances to stop')             

                 