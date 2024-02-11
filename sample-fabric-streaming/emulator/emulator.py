# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Run the script without parameters for help.
# The script can be configured via file. Use emulator.ini.example as a reference.

import asyncio
import datetime
import os
import json
import uuid
from dotenv import load_dotenv
from azure.eventhub import EventData
from azure.eventhub.aio import EventHubProducerClient, EventHubConsumerClient
from azure.eventhub.extensions.checkpointstoreblobaio import BlobCheckpointStore
from configargparse import ArgParser


class Emulator:
    def __init__(self, target_event_hub_connection_string,target_event_hub_name ):
        self.target_event_hub_connection_string = target_event_hub_connection_string
        self.target_event_hub_name = target_event_hub_name
        self._power_consumption_wh = 1000
        self.ev_charging = False
        self.ev_plugged_in = False
        self.ev_battery_level = 50

        self.producer = EventHubProducerClient.from_connection_string(
            conn_str=self.target_event_hub_connection_string,
            eventhub_name=self.target_event_hub_name,
        )

    def power_consumption_wh(self):
        return self._power_consumption_wh + (1000 if self.ev_charging else 0)

    # Send telemetry of meter and EV every 60 seconds
    async def send(self):
        while True:
            data = {
                "EventInstanceId": str(uuid.uuid4()),
                "EventName": "SensorReadingEvent",
                "EventTime": datetime.datetime.utcnow().isoformat(),
                "Device": {
                    "Id": "de286df4-71ea-427e-8519-104830ae1559",
                    "Type": "Meter",
                },
                "Characteristics": [
                    {
                        "Name": "power_consumption_wh",
                        "Value": str(self.power_consumption_wh()),
                        "ValueType": "decimal",
                    }
                ],
            }
            await self.send_event(data)

            data = {
                "EventInstanceId": str(uuid.uuid4()),
                "EventName": "SensorReadingEvent",
                "EventTime": datetime.datetime.utcnow().isoformat(),
                "Device": {
                    "Id": "85fd20a9-c85c-4dc0-a6c9-2e20d5df1de2",
                    "Type": "ElectricVehicle",
                },
                "Characteristics": [
                    {
                        "Name": "ev_plugged_in",
                        "Value": str(self.ev_plugged_in),
                        "ValueType": "boolean",
                    },
                    {
                        "Name": "ev_battery_level",
                        "Value": str(self.ev_battery_level),
                        "ValueType": "decimal",
                    },
                    {
                        "Name": "ev_charging",
                        "Value": str(self.ev_charging),
                        "ValueType": "boolean",
                    },
                ],
            }
            await self.send_event(data)

            await asyncio.sleep(60)

    # Helper to send events over eventstream
    async def send_event(self, data):
        print(f"Sending data:{data}")

        async with self.producer:
            await self.producer.send_event(EventData(json.dumps(data)))

  
 

    # Print the status of the emulator
    def print_status(self):
        print(f"Power consumption: {self.power_consumption_wh()}")
        print(f"EV charging: {self.ev_charging}")
        print(f"EV plugged in: {self.ev_plugged_in}")
        print(f"EV battery: {self.ev_battery_level}")

    # Main loop
    async def run(self):
        tasks = [self.send()]
        await asyncio.gather(*tasks)



source_event_hub_connection_string=os.environ['source_event_hub_connection_string']
source_event_hub_name=os.environ['source_event_hub_name']
target_event_hub_connection_string=os.environ['target_event_hub_connection_string']
target_event_hub_name=os.environ['target_event_hub_name']
storage_connection_string=os.environ['storage_connection_string']
storage_container=os.environ['storage_container']

emulator = Emulator(target_event_hub_connection_string,target_event_hub_name)

asyncio.run(emulator.run())