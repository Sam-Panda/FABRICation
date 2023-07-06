import os
from azure.storage.blob import BlobServiceClient
from dotenv import load_dotenv
import datetime
import csv
import random
import time
import names
import random

# declare some variables here 
number_of_files_to_be_generated = 10
number_of_seconds_to_be_waited = 5

def create_random_names():
    name = names.get_full_name()


def create_file():
    load_dotenv()
    connect_str = os.environ['connect_str']
    blob_service_client = BlobServiceClient.from_connection_string(connect_str)
    container_name = "misc"
    container_client = blob_service_client.get_container_client(container_name)
    now = datetime.datetime.now()
    file_name = "MyFirstBlob.csv"


    # Format the date and time as a string
    date_time_string = now.strftime("%Y-%m-%d_%H-%M-%S")
    new_file_name = f"/streamcsvfiles/{date_time_string}_{file_name}"
    blob_client = blob_service_client.get_blob_client(container_name, new_file_name)

    # Set up the headers and data
    headers = ['Name', 'Age', 'Country']
    data = []
    for i in range(10):
        name = create_random_names()
        age = random.randint(10, 60)
        country = random.choice(['USA', 'UK', 'Australia', 'Canada', 'India', "dummy"])
        data.append([name, age, country])

    file_name = 'temp_random.csv'
    with open(file_name, mode='w', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(headers)
        writer.writerows(data)

    with open(file_name, "rb") as data:
        blob_client.upload_blob(data)
        print(f"files_uploaded - {blob_client.url}")

def __init__():
    for i in range(number_of_files_to_be_generated):
        create_file()
        time.sleep(number_of_seconds_to_be_waited)
        
# reading .dat file in pyspark
# https://stackoverflow.com/questions/56580413/how-to-read-dat-file-in-pyspark
