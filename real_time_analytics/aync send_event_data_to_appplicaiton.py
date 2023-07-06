

import time
import asyncio
import os
import random
from dotenv import load_dotenv
from datetime import datetime
import datetime
import uuid
import json
import logging
from azure.eventhub.aio import EventHubProducerClient
from azure.eventhub.exceptions import EventHubError
from azure.eventhub import EventData
import nest_asyncio
nest_asyncio.apply()
load_dotenv()


CONNECTION_STR = os.environ['EVENT_STREAM_CONN_STR']
EVENTHUB_NAME = os.environ['EVENT_STREAM_APP_NAME']



async def run():
    # [START eventhub_producer_client_close_async]
    import os
    from azure.eventhub.aio import EventHubProducerClient
    from azure.eventhub import EventData

    event_hub_connection_str = CONNECTION_STR
    eventhub_name = EVENTHUB_NAME
    number_of_events=11 # Assign default value
    number_of_devices=5
    producer = EventHubProducerClient.from_connection_string(
        conn_str=event_hub_connection_str,
        eventhub_name=eventhub_name  # EventHub name should be specified if it doesn't show up in connection string.
    )
    devices = []
    for x in range(0, number_of_devices):
        devices.append(str(uuid.uuid4()))

    for dev in devices:
        event_data_batch = await producer.create_batch() # Create a batch. You will add events to the batch later.
        # Create a dummy reading.
        for x in range(0, number_of_events):
            reading = {'id': dev, 'timestamp': str(datetime.datetime.utcnow()), 'uv': random.random(), 'temperature': random.randint(70, 100), 'humidity': random.randint(70, 100)}
            s = json.dumps(reading) # Convert the reading into a JSON string.
            print(s)
            # while can_add:
            # try:
            event_data_batch.add(EventData(s)) # Add event data to the batch.
            # except ValueError:
            #     can_add = False # EventDataBatch object reaches max_size.
        async with producer:
            await producer.send_batch(event_data_batch) # Send the batch of events to the event hub.


    await producer.close()
    
if __name__ == '__main__':
    loop = asyncio.get_event_loop()
    loop.run_until_complete(run())
    # example_eventhub_async_producer_send_and_close()
