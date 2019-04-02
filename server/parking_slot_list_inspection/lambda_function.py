import json

import boto3

dynamodb = boto3.resource(
    'dynamodb',
    region_name='us-east-1',
    endpoint_url='https://dynamodb.us-east-1.amazonaws.com')
slot_table = dynamodb.Table('parking_slots')
configuration_table = dynamodb.Table('configuration')


def lambda_handler(event, context):
    next_empty_slot = configuration_table.get_item(
        Key={'id': 'next_empty_slot'})['Item']['value']

    empty_slots = []

    while True:
        if next_empty_slot == None:
            break

        empty_slots.append(next_empty_slot)

        slot = slot_table.get_item(Key={'id': next_empty_slot})['Item']

        next_empty_slot = slot['nextEmptySlot']

    return {"statusCode": 200, "body": json.dumps(empty_slots)}
