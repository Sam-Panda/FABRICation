

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



async def get_flight_data(epoch_start_time, epoch_end_time):
    loop = asyncio.get_event_loop()
    import requests
    # getting the response for every 1 minute
    future1= loop.run_in_executor(None, requests.get, f'https://opensky-network.org/api/flights/all?&begin={epoch_start_time}&end={epoch_end_time}')
    response = await future1
    data = response.json()
    return data

async def run(data):
    # [START eventhub_producer_client_close_async]
    import os
    from azure.eventhub.aio import EventHubProducerClient
    from azure.eventhub import EventData

    event_hub_connection_str = CONNECTION_STR
    eventhub_name = EVENTHUB_NAME

    producer = EventHubProducerClient.from_connection_string(
        conn_str=event_hub_connection_str,
        eventhub_name=eventhub_name  # EventHub name should be specified if it doesn't show up in connection string.
    )


    flight_details = data
    # print(flight_details)
    event_data_batch = await producer.create_batch() # Create a batch. You will add events to the batch later.
    for flight_detail in flight_details:
        event = {
            'icao24': flight_detail['icao24'], 
            'firstSeen': flight_detail['firstSeen'], 
            'firstSeen_time': datetime.datetime.fromtimestamp(flight_detail['firstSeen']).strftime('%Y-%m-%d %H:%M:%S'),
            'estDepartureAirport': flight_detail['estDepartureAirport'], 
            'lastSeen': flight_detail['lastSeen'], 
            'lastseen_time': datetime.datetime.fromtimestamp(flight_detail['lastSeen']).strftime('%Y-%m-%d %H:%M:%S'),
            'estArrivalAirport': flight_detail['estArrivalAirport'],
            'durationOfFlightInMinutes': (flight_detail['lastSeen']-flight_detail['firstSeen'])/60,
            'callsign': flight_detail['callsign'], 
            'estDepartureAirportHorizDistance': flight_detail['estDepartureAirportHorizDistance'],
            'estDepartureAirportVertDistance': flight_detail['estDepartureAirportVertDistance'],
            'estArrivalAirportHorizDistance': flight_detail['estArrivalAirportHorizDistance'],
            'estArrivalAirportVertDistance': flight_detail['estArrivalAirportVertDistance'],
            'departureAirportCandidatesCount': flight_detail['departureAirportCandidatesCount'],
            'arrivalAirportCandidatesCount': flight_detail['arrivalAirportCandidatesCount']
        }
        s = json.dumps(event) # Convert the reading into a JSON string.
        print(s)
        event_data_batch.add(EventData(s)) # Add event data to the batch.
    async with producer:
        await producer.send_batch(event_data_batch) # Send the batch of events to the event hub.
    await producer.close()
    
if __name__ == '__main__':
    interval = 7200 # 60 minutes
    current_epoch_time= int(time.time())
    epoch_start_time = current_epoch_time - interval
    epoch_end_time = current_epoch_time
    loop = asyncio.get_event_loop()
    # while True:
    print(f"epoch_start_time: {epoch_start_time}, epoch_end_time: {epoch_end_time}")
    data = loop.run_until_complete(get_flight_data(epoch_start_time, epoch_end_time))
    # print(data)
    loop.run_until_complete(run(data))
    # sleep the code for one minute
    #time.sleep(interval)
    epoch_start_time = epoch_end_time+1
    epoch_end_time = int(time.time())
        
        # example_eventhub_async_producer_send_and_close()
