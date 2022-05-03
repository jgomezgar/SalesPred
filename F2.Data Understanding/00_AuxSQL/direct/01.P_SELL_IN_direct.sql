/*################## 7 min #################################################*/
-- OUTPUT: [STAGING_2].[dbo].XXX_P_Sell_IN_direct_Periods_10d

-- AUXILIARY OUTPUT:
--		[STAGING_2].[dbo].XXX_P_Sell_IN_Direct_ITG
--		[STAGING_2].[dbo].XXX_P_Sell_IN_Direct_ITG_backbone




USE [ITE_PRD]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

DECLARE @t1 DATETIME;
DECLARE @t2 DATETIME;


SET @t1 = GETDATE();


IF OBJECT_ID('[STAGING_2].[dbo].XXX_P_Sell_IN_Direct_ITG', 'U') IS NOT NULL
 DROP TABLE [STAGING_2].[dbo].XXX_P_Sell_IN_Direct_ITG;
 
 select	
		d.[CAL_DATE],
		d.CAL_MONTH,
		f.[CUSTOMER_ID]  CUSTOMER_ID,
		b.SUBCATEGORY MIDCATEGORY,
		b.[BRANDFAMILY_ID]  BRANDFAMILY_ID,
		ceiling(sum(f.[VOL_EQUI]))  SI_ITG_WSE
into [STAGING_2].[dbo].XXX_P_Sell_IN_Direct_ITG
from	ITE.FACT_SMLD_Smoke_ITG	f
	join	ITE.T_DAY	d
	  on 	(f.[SALESDATE] = d.[CAL_DAY])    
	join	ITE.T_BRANDPACKS	b
	  on 	(f.[BRANDPACK_ID] = b.[BRANDPACK_ID] )
where	d.CAL_MONTH >=  '201704' 
	and b.SUBCATEGORY in (N'BLOND', N'RYO')
group by
		d.[CAL_DATE],
		d.CAL_MONTH,
		f.[CUSTOMER_ID],
		b.SUBCATEGORY,
		b.[BRANDFAMILY_ID]
;
IF OBJECT_ID('[STAGING_2].[dbo].XXX_P_Sell_IN_Direct_ITG_backbone', 'U') IS NOT NULL
 DROP TABLE [STAGING_2].[dbo].XXX_P_Sell_IN_Direct_ITG_backbone;

select	
		
		cyf.[CUSTOMER_ID]  CUSTOMER_ID,
		cyf.MIDCATEGORY MIDCATEGORY,
		cyf.[BRANDFAMILY_ID]  BRANDFAMILY_ID,
		m3.CAL_DATE,
		m3.CAL_MONTH,
		m3.tercio,
		m3.date_init,
		m3.date_end,
		m3.NUM_SELLING_DAYS,
		m3.NUM_DAYS
into [STAGING_2].[dbo].XXX_P_Sell_IN_Direct_ITG_backbone
from	 [STAGING_2].[dbo].XXX_P_Time_Sell_tercio M3 
		cross join (
			select distinct 
				i.[CUSTOMER_ID]  CUSTOMER_ID,
				i.MIDCATEGORY MIDCATEGORY,
				i.[BRANDFAMILY_ID]  BRANDFAMILY_ID
			From [STAGING_2].[dbo].XXX_P_Sell_IN_Direct_ITG i) cyf

;
IF OBJECT_ID('[STAGING_2].[dbo].XXX_P_Sell_IN_Direct_Periods_10d', 'U') IS NOT NULL
 DROP TABLE [STAGING_2].[dbo].XXX_P_Sell_IN_Direct_Periods_10d;

with  MRKT_Sales as (

select	
		d.[CAL_DATE],
		d.CAL_MONTH,
		f.[CUSTOMER_ID]  CUSTOMER_ID,
		f.MIDCATEGORY,
		ceiling(sum(f.Mrkt_WSE))  SI_Mrkt_WSE
from	ITE.[V_FACT_Sales_Target_WSE_Daily]	f
	join	ITE.T_DAY	d
	  on 	(f.DIA = d.DIA)    
where	
	d.CAL_MONTH >= '201704' 
	and f.MIDCATEGORY in (N'BLOND', N'RYO')
group by
		d.[CAL_DATE],
		d.CAL_MONTH,
		f.[CUSTOMER_ID],
		f.MIDCATEGORY

)



Select 
		bb.[CUSTOMER_ID]  CUSTOMER_ID,
		bb.MIDCATEGORY MIDCATEGORY,
		bb.[BRANDFAMILY_ID]  BRANDFAMILY_ID,
--		bb.CAL_DATE,
		bb.CAL_MONTH,
		bb.tercio,
		bb.date_init,
		bb.date_end,
		bb.NUM_SELLING_DAYS,
		bb.NUM_DAYS,
		isnull(sum(SI_ITG_WSE),0) SI_ITG_WSE,
		case when isnull(sum(SI_Mrkt_WSE),0)< isnull(sum(SI_ITG_WSE),0) then isnull(sum(SI_ITG_WSE),0) else isnull(sum(SI_Mrkt_WSE),0) end SI_Mrkt_WSE
into [STAGING_2].[dbo].XXX_P_Sell_IN_Direct_Periods_10d
FROM [STAGING_2].[dbo].XXX_P_Sell_IN_Direct_ITG_backbone bb 
left join [STAGING_2].[dbo].XXX_P_Sell_IN_Direct_ITG i
		on (bb.CAL_DATE = i.CAL_DATE and
		bb.[CUSTOMER_ID] = i.CUSTOMER_ID and
		bb.[BRANDFAMILY_ID] = i.[BRANDFAMILY_ID])			

left join  MRKT_Sales m
		on (bb.CAL_DATE = m.CAL_DATE and
		bb.[CUSTOMER_ID] = m.CUSTOMER_ID and
		bb.MIDCATEGORY = m.MIDCATEGORY)	

group by
		bb.[CUSTOMER_ID],
		bb.MIDCATEGORY,
		bb.[BRANDFAMILY_ID],
		bb.CAL_MONTH,
		bb.tercio,
		bb.date_init,
		bb.date_end,
		bb.NUM_SELLING_DAYS,
		bb.NUM_DAYS

;
SET @t2 = GETDATE();
SELECT '01.XXX_P_Sell_IN_Direct.sql' as SCRIPT,
DATEDIFF(mi,@t1,@t2) AS elapsed_min;
