#!/usr/bin/env python
# coding: utf-8

# ## NycYellowTaxi_Notebook_00_DataConversion
# 
# 
# 

# In[1]:


# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

spark.conf.set("sprk.sql.parquet.vorder.enabled", "true")
spark.conf.set("spark.microsoft.delta.optimizeWrite.enabled", "true")
spark.conf.set("spark.microsoft.delta.optimizeWrite.binSize", "1073741824")
spark.conf.set("spark.sql.parquet.enableVectorizedReader","false")


# ### Below is to process from the folder level

# In[2]:


input_file_path = f"Files/nycyellowtaxi-raw"
output_path = "Files/nycyellowtaxi-bronze"
keywords_to_be_considered =['2022']


# In[3]:


from notebookutils import mssparkutils
_input_files_path =   mssparkutils.fs.ls(f"{input_file_path}")
input_files_path = []
for fileinfo in _input_files_path:
    input_files_path.append(fileinfo.path)

files_path = []
filtered_list_of_path = []
for keyword in keywords_to_be_considered:
    filtered_list_of_path = [i for i in input_files_path if keyword in i]
    for f in filtered_list_of_path:
        files_path.append(f)


# ### change the data type of the incoming files according to the Bronze table. 

# In[4]:


import os
import shutil
TEMPORARY_TARGET = f'{output_path}/__temp'
try:
        mssparkutils.fs.rm(TEMPORARY_TARGET, recurse=True)

except:
       print("Folders are not present")

from pyspark.sql.functions import col, lit
for file_path in  files_path:
        # print(file_path)
        path = file_path
        output_file_name = path.split("/")[-1]
        output_full_path = f"{output_path}/{output_file_name}"
        # print(output_full_path)
        df_preprocessed= spark.read.parquet(path)
        df = df_preprocessed.select(col("VendorID").cast("long"), col("tpep_pickup_datetime").cast("timestamp"), \
                col("tpep_dropoff_datetime").cast("timestamp"), \
                col("passenger_count").cast("long"), col("trip_distance").cast("double"),\
                col("RatecodeID").cast("int"), \
                col("store_and_fwd_flag").cast("string"), \
                col("PULocationID").cast("int"),col("DOLocationID").cast("int"),\
                col("payment_type").cast("int"), \
                col("fare_amount").cast("double"), \
                col("extra").cast("double"),col("mta_tax").cast("double"), \
                col("tip_amount").cast("double"),col("tolls_amount").cast("double"),
                col("improvement_surcharge").cast("double"),col("total_amount").cast("double"), \
                col("congestion_surcharge").cast("double"), \
                col("airport_fee").cast("double") \
                )
        df = df.withColumn("file_name", lit(output_file_name))
        df.repartition(1).write.mode("overwrite").format("parquet").save(TEMPORARY_TARGET)
        _input_files_path =   mssparkutils.fs.ls(f"{TEMPORARY_TARGET}")
        input_files_path = []
        for fileinfo in _input_files_path:
                input_files_path.append(fileinfo.path)
        _file = [i for i in input_files_path if 'part-' in i][0]
        print(f"temp_file: {_file}")
        print(f"output_file: {output_full_path}")
        mssparkutils.fs.cp(_file,output_full_path)
        mssparkutils.fs.rm(TEMPORARY_TARGET, recurse=True)


