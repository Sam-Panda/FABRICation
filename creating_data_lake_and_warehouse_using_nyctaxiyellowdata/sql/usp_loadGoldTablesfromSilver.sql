-- EXEC dbo.usp_dataload_raw_gold
CREATE or ALTER PROC dbo.usp_dataload_raw_gold
AS

BEGIN TRAN
	BEGIN TRY 

		Drop table if exists dbo.dim_holidays;
		Select a.* INTO dbo.dim_holidays FROM (
			select *, convert(varchar(10),[date], 112) as 'shortdate', convert(varchar(10),[date], 23) as 'onlyDate' from LHYellowTaxi.[dbo].[silver_holidays]
			Where countryOrRegion = 'United States' 
			AND [date] BETWEEN CAST('20110101' AS DATETIME2(6)) AND GETDATE()
		) a


		DROP TABLE IF EXISTS dbo.fact_nycyellotaxi;		
		Select  a.* INTO dbo.fact_nycyellotaxi FROM (
				   Select  _a.*, CASE WHEN 
											holi.date IS NULL THEN 'WorkingDay' ELSE 'Holiday'
										END AS 'IsHoliday'
				   from (
					   SELECT  VendorID
							,convert(varchar(10),tpep_pickup_datetime, 112) as 'shortpickupdate'
							,convert(varchar(10),tpep_pickup_datetime, 23) as 'onlypickupdate'
							,tpep_pickup_datetime
							,convert(varchar(10),tpep_dropoff_datetime, 112) as 'shortdropoffdate'
							,convert(varchar(10),tpep_dropoff_datetime, 23) as 'onlydropoffdate'
							,tpep_dropoff_datetime
							,passenger_count
							,trip_distance
							,RatecodeID
							,store_and_fwd_flag
							,PULocationID
							,DOLocationID
							,payment_type
							,fare_amount
							,extra
							,mta_tax
							,tip_amount
							,tolls_amount
							,improvement_surcharge
							,total_amount
							,congestion_surcharge
							,airport_fee
						FROM LHYellowTaxi.dbo.silver_nycyellowtaxi
							WHERE [passenger_count] <= 8
								AND [fare_amount] <= 500
								AND [total_amount] <= 500
								AND [tip_amount] <= 500
								AND [tolls_amount] <= 500
								AND [improvement_surcharge] <= 500
								AND [trip_distance] <= 125
								AND [tpep_pickup_datetime] < GETDATE()
								AND [tpep_pickup_datetime] < [tpep_dropoff_datetime]
								AND [tpep_pickup_datetime] BETWEEN CAST('20110101' AS DATETIME2(6)) AND GETDATE()
						
							) _a
							left join LHYellowTaxi.[dbo].[silver_holidays] as holi 
								on  _a.shortpickupdate = convert(varchar(10),holi.[date], 112)
								AND holi.countryOrRegion='United States' 
				)a


		Drop table if exists dbo.dim_paymentCode 
		Select a.* into dbo.dim_paymentCode FROM (
		select * from [LHYellowTaxi].[dbo].[silver_paymentCode] ) a

		Drop table if exists dbo.dim_ratecode 
		Select a.* into dbo.dim_ratecode FROM (
		select * from [LHYellowTaxi].[dbo].[silver_ref_ratecode] ) a

		Drop table if exists dbo.dim_taxiZones
		Select a.* into dbo.dim_taxiZones FROM (
		select * from [LHYellowTaxi].[dbo].[silver_ref_taxiZones] ) a

		END TRY
		BEGIN CATCH
			BEGIN
				ROLLBACK TRAN;
				PRINT 'ROLLBACK';
			END

		END CATCH;
IF @@TRANCOUNT >0
BEGIN
    PRINT 'COMMIT';
    COMMIT TRAN;
END