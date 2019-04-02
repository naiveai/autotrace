import datetime
import enum
import json

import boto3

dynamodb = boto3.resource(
    'dynamodb',
    region_name='us-east-1',
    endpoint_url='https://dynamodb.us-east-1.amazonaws.com')
slot_table = dynamodb.Table('parking_slots')
vehicle_table = dynamodb.Table('vehicles')
configuration_table = dynamodb.Table('configuration')


class StateChanges(enum.Enum):
    PARK_IN = 'PARK-IN'
    PARK_OUT = 'PARK-OUT'
    MAINT_IN = 'MAINT-IN'
    MAINT_OUT = 'MAINT-OUT'
    MOVE = 'MOVE'


def lambda_handler(event, context):
    if 'queryStringParameters' in event:
        action = event['resource'][1:].upper()
        event = event['queryStringParameters']
        event['action'] = action

    state_change = event['action']
    timestamp = datetime.datetime.now().strftime("%d-%b-%Y (%H:%M:%S.%f)")

    next_empty_slot = configuration_table.get_item(
        Key={'id': 'next_empty_slot'})['Item']['value']

    if state_change == StateChanges.PARK_IN.value:
        if next_empty_slot is None:
            return {
                "statusCode": 403,
                "body": json.dumps({
                    "error": "This park is full."
                })
            }

        if vehicle_table.query(
                KeyConditionExpression=boto3.dynamodb.conditions.Key('VIN').eq(
                    event['VIN']))['Items'] != []:
            return {
                "statusCode": 403,
                "body": json.dumps({
                    "error": "This VIN already exists."
                })
            }

        vehicle_table.put_item(
            Item={
                'VIN':
                event['VIN'],
                'history': [{
                    'change': state_change,
                    'timestamp': timestamp,
                    'slot': next_empty_slot
                }],
                'current_slot':
                next_empty_slot,
                'in_lot':
                True,
            })

        next_slot = slot_table.get_item(
            Key={'id': next_empty_slot})['Item']['nextEmptySlot']

        slot_table.update_item(
            Key={'id': next_empty_slot},
            UpdateExpression="set VIN = :vin",
            ExpressionAttributeValues={':vin': event['VIN']})

        configuration_table.update_item(
            Key={'id': 'next_empty_slot'},
            UpdateExpression="set #v = :next",
            ExpressionAttributeNames={'#v': "value"},
            ExpressionAttributeValues={':next': next_slot})

        return {
            "statusCode": 201,
            "body": json.dumps({
                "slot": next_empty_slot
            })
        }

    if vehicle_table.query(
            KeyConditionExpression=boto3.dynamodb.conditions.Key('VIN').eq(
                event['VIN']))['Items'] == []:
        return {
            "statusCode": 403,
            "body": json.dumps({
                "error": "This VIN does not exist."
            })
        }

    vehicle = vehicle_table.get_item(Key={'VIN': event['VIN']})['Item']

    if vehicle['history'][0]['change'] == StateChanges.PARK_OUT.value:
        return {
            "statusCode": 403,
            "body": json.dumps({
                "error": "This VIN is parked out."
            })
        }

    if state_change == StateChanges.MAINT_IN.value:
        if vehicle['in_lot']:
            return {
                "statusCode": 403,
                "body": json.dumps({
                    "error": "This VIN is already in the lot."
                })
            }

        if next_empty_slot is None:
            return {
                "statusCode": 403,
                "body": json.dumps({
                    "error": "This park is full."
                })
            }

        vehicle_table.update_item(
            Key={'VIN': event['VIN']},
            UpdateExpression=
            'set history = list_append(:new_hist, history), current_slot = :slot, in_lot = :in',
            ExpressionAttributeValues={
                ':new_hist': [{
                    'change': state_change,
                    'timestamp': timestamp,
                    'slot': next_empty_slot
                }],
                ':slot':
                next_empty_slot,
                ':in':
                True
            })

        next_slot = slot_table.get_item(
            Key={'id': next_empty_slot})['Item']['nextEmptySlot']

        slot_table.update_item(
            Key={'id': next_empty_slot},
            UpdateExpression="set VIN = :vin",
            ExpressionAttributeValues={':vin': event['VIN']})

        configuration_table.update_item(
            Key={'id': 'next_empty_slot'},
            UpdateExpression="set #v = :next",
            ExpressionAttributeNames={'#v': "value"},
            ExpressionAttributeValues={':next': next_slot})

        return {
            "statusCode": 200,
            "body": json.dumps({
                "slot": next_empty_slot
            })
        }

    if not vehicle['in_lot']:
        return {
            "statusCode": 403,
            "body": json.dumps({
                "error": "This VIN is not in the lot."
            })
        }

    if state_change == StateChanges.PARK_OUT.value or state_change == StateChanges.MAINT_OUT.value:
        current_slot = vehicle_table.get_item(
            Key={'VIN': event['VIN']})['Item']['current_slot']

        vehicle_table.update_item(
            Key={'VIN': event['VIN']},
            UpdateExpression=
            'set history = list_append(:new_hist, history), current_slot = :slot, in_lot = :in',
            ExpressionAttributeValues={
                ':new_hist': [{
                    'change': state_change,
                    'timestamp': timestamp,
                    'slot': None,
                }],
                ':slot':
                None,
                ':in':
                False,
            })

        slot_table.update_item(
            Key={'id': current_slot},
            UpdateExpression="set VIN = :vin, nextEmptySlot = :next",
            ExpressionAttributeValues={
                ':vin': None,
                ':next': next_empty_slot
            })

        configuration_table.update_item(
            Key={'id': 'next_empty_slot'},
            UpdateExpression="set #v = :next",
            ExpressionAttributeNames={'#v': "value"},
            ExpressionAttributeValues={':next': current_slot})

        return {"statusCode": 200}

    elif state_change == StateChanges.MOVE.value:
        new_slot = event['newSlot']

        current_slot = vehicle_table.get_item(
            Key={'VIN': event['VIN']})['Item']['current_slot']

        new_slot_object = slot_table.get_item(Key={'id': new_slot})['Item']

        if new_slot_object['VIN'] is not None:
            return {
                "statusCode":
                403,
                "body":
                json.dumps({
                    "error": "Slot {} is not empty.".format(new_slot)
                })
            }

        vehicle_table.update_item(
            Key={'VIN': event['VIN']},
            UpdateExpression=
            'set history = list_append(:new_hist, history), current_slot = :slot',
            ExpressionAttributeValues={
                ':new_hist': [{
                    'change': state_change,
                    'timestamp': timestamp,
                    'slot': new_slot,
                }],
                ':slot':
                new_slot,
            })

        new_next_empty_slot = new_slot_object['nextEmptySlot']

        slot_table.update_item(
            Key={'id': current_slot},
            UpdateExpression="set VIN = :vin, nextEmptySlot = :next",
            ExpressionAttributeValues={
                ':vin': None,
                ':next': new_next_empty_slot
            })

        slot_table.update_item(
            Key={'id': new_slot},
            UpdateExpression="set VIN = :vin",
            ExpressionAttributeValues={':vin': event['VIN']})

        configuration_table.update_item(
            Key={'id': 'next_empty_slot'},
            UpdateExpression="set #v = :next",
            ExpressionAttributeNames={'#v': "value"},
            ExpressionAttributeValues={':next': current_slot})

        return {"statusCode": 200}
