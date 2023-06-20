#!/usr/bin/env python
# coding: utf-8

# ## NycYellowTaxi_Notebook_01_Bronze_to_Silver(Optional)
# 
# 
# 

# #### Enabling spark settings for  Delta Lake table optimization and V-Order
# [documentation](https://learn.microsoft.com/en-us/fabric/data-engineering/delta-optimization-and-v-order?tabs=sparksql)

# In[2]:


spark.conf.set("sprk.sql.parquet.vorder.enabled", "true")
spark.conf.set("spark.microsoft.delta.optimizeWrite.enabled", "true")
spark.conf.set("spark.microsoft.delta.optimizeWrite.binSize", "1073741824")
spark.conf.set("spark.sql.parquet.enableVectorizedReader","false")


# In[4]:


from pyspark.sql.functions import col
df = spark.read.parquet("Files/nycyellowtaxi-bronze/*")


# In[5]:


df.write.mode("append").format("delta").save("Tables/NB_raw_data_yellowtaxi_bronze")


# In[ ]:


get_ipython().run_cell_magic('sql', '', '\r\nselect count (*) from NB_raw_data_yellowtaxi_bronze\n')

