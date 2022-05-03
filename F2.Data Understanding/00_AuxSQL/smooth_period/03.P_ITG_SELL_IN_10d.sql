/*################## 7 min #################################################*/
-- OUTPUT: [STAGING_2].[dbo].XXX_P_Sell_IN_Periods_10d

-- AUXILIARY OUTPUT:
--		[STAGING_2].[dbo].XXX_P_Sell_IN_ITG_10d
--		[STAGING_2].[dbo].XXX_P_Sell_IN_Mrkt_10d
--		[STAGING_2].[dbo].XXX_P_Sell_IN_ITG_Periods_10d
--		[STAGING_2].[dbo].XXX_P_Time_Sell_tercio

-- INPUT:
--		[STAGING_2].[dbo].[XXX_P_Sell_IN_ITG_Periods]
--		[STAGING_2].[dbo].[XXX_P_Sell_IN_Mrkt_Periods]
--			[ITE_PRD].[ITE].T_DAY

--		[ITE_PRD].[ITE].T_DAY


USE [ITE_PRD]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

DECLARE @t1 DATETIME;
DECLARE @t2 DATETIME;


SET @t1 = GETDATE();


/*####################### 0 min ################################################*/
IF OBJECT_ID('[STAGING_2].[dbo].XXX_P_Time_Sell_tercio', 'U') IS NOT NULL
 DROP TABLE [STAGING_2].[dbo].XXX_P_Time_Sell_tercio;
 
with tercio as( 
select *, 
 NTILE(3) OVER (
    PARTITION BY CAL_MONTH
    ORDER BY CAL_DATE
) tercio
from ite.T_DAY
where SELLING_DAY = 1. and
CAL_MONTH >= '201704' --and convert(varchar(6),GETDATE()-1,112)
)

, selling_days as(
select CAL_MONTH, tercio,
case when tercio = 1 then DATEADD(DD,-DAY(MIN(CAL_DATE)) +1, MIN(CAL_DATE)) else MIN(CAL_DATE) end date_init, 
case when tercio = 3 then  dateadd(dd,-1,convert(date,convert(varchar(6),DATEADD(M,1,MAX(CAL_DATE)),112) + '01',112)) else MAX(CAL_DATE) end date_end,
SUM(SELLING_DAY) NUM_SELLING_DAYS
from tercio
group by CAL_MONTH, tercio)

, decenas as (
select * from selling_days s1 where tercio = 3 union all
select 	s1.CAL_MONTH,
	s1.tercio,
	s1.date_init,
	dateadd(dd,-1,s2.date_init) date_end,
	s1.NUM_SELLING_DAYS
from 
selling_days s1 join selling_days s2 
on s1.CAL_MONTH = s2.CAL_MONTH and s1.tercio  = s2.tercio -1
)

select 
	d.CAL_DATE, 
	dec.CAL_MONTH,
	dec.tercio,
	dec.date_init,
	dec.date_end,
	convert(int,dec.NUM_SELLING_DAYS) NUM_SELLING_DAYS,
	DATEDIFF(DAY,dec.date_init, dec.date_end)+1 NUM_DAYS
into [STAGING_2].[dbo].XXX_P_Time_Sell_tercio
from decenas dec 
join ite.T_DAY d 
 on d.CAL_DATE between date_init and date_end



/*########################### 4 min ###################################*/
IF OBJECT_ID('[STAGING_2].[dbo].XXX_P_Sell_IN_ITG_10d', 'U') IS NOT NULL
 DROP TABLE [STAGING_2].[dbo].XXX_P_Sell_IN_ITG_10d;

with Sell_IN_ITG_10d as(
select	
		m3.tercio,
		m3.date_init,
		m3.date_end,
		m3.NUM_SELLING_DAYS,
		m3.NUM_DAYS,
		SI.CAL_DATE,
		SI.CAL_DATE_end,
		SI.CUSTOMER_ID,
		SI.BRANDFAMILY_ID,
		SI.SI_ITG_WSE SI_ITG_WSE_ori,
		SI.SI_MRKT_adjust SI_MRKT_adjust_ori,		
		sum(sum(d.SELLING_DAY)) over (partition by SI.CAL_DATE,SI.CUSTOMER_ID, SI.BRANDFAMILY_ID )days_btw_order,
		sum(sum(d.SELLING_DAY)) over (partition by m3.date_init, SI.CAL_DATE, SI.CUSTOMER_ID, SI.BRANDFAMILY_ID )days_in_tercio,
		ceiling(isnull(SI.SI_ITG_WSE/nullif(sum(sum(d.SELLING_DAY)) over (partition by SI.CAL_DATE,SI.CUSTOMER_ID, SI.BRANDFAMILY_ID ),0),0)
											*sum(sum(d.SELLING_DAY)) over (partition by m3.date_init, SI.CAL_DATE,SI.CUSTOMER_ID, SI.BRANDFAMILY_ID )) SI_ITG_WSE,
		ceiling(isnull(SI.SI_MRKT_adjust/nullif(sum(sum(d.SELLING_DAY)) over (partition by SI.CAL_DATE,SI.CUSTOMER_ID, SI.BRANDFAMILY_ID ),0),0)
											*sum(sum(d.SELLING_DAY)) over (partition by m3.date_init, SI.CAL_DATE,SI.CUSTOMER_ID, SI.BRANDFAMILY_ID ))SI_Mrkt_WSE_adjust

from [STAGING_2].[dbo].XXX_P_Sell_IN_ITG_Periods SI
join ite.T_DAY d on d.CAL_DATE between SI.CAL_DATE and	SI.CAL_DATE_end
join [STAGING_2].[dbo].XXX_P_Time_Sell_tercio M3 on (m3.CAL_DATE = d.CAL_DATE)

group by
		m3.tercio,
		m3.date_init,
		m3.date_end,
		m3.NUM_SELLING_DAYS,
		m3.NUM_DAYS,		
		SI.CAL_DATE,
		SI.CAL_DATE_end,
		SI.CUSTOMER_ID,
		SI.BRANDFAMILY_ID,
		SI.SI_ITG_WSE,
		SI.SI_MRKT_adjust
)

select	
		tercio,
		date_init CAL_DATE,
		date_end CAL_DATE_end,
		NUM_SELLING_DAYS,
		NUM_DAYS,
		ceiling(avg(days_btw_order)) days_btw_order,
		ceiling(sum(days_in_tercio)) days_in_tercio,
		CUSTOMER_ID,
		BRANDFAMILY_ID,
		sum(SI_ITG_WSE) SI_ITG_WSE,
		sum(SI_Mrkt_WSE_adjust) SI_Mrkt_WSE_adjust		
into [STAGING_2].[dbo].XXX_P_Sell_IN_ITG_10d		
from  Sell_IN_ITG_10d
group by
		tercio,
		date_init,
		date_end,
		NUM_SELLING_DAYS,
		NUM_DAYS,
		CUSTOMER_ID,
		BRANDFAMILY_ID
--order by SI.CUSTOMER_ID, date_init, SI.BRANDFAMILY_ID

/*####################### 2 min ################################################*/
IF OBJECT_ID('[STAGING_2].[dbo].XXX_P_Sell_IN_Mrkt_10d', 'U') IS NOT NULL
 DROP TABLE [STAGING_2].[dbo].XXX_P_Sell_IN_Mrkt_10d;

with Sell_IN_Mrkt_10d as(


select	
		m3.tercio,
		m3.date_init,
		m3.date_end,
		m3.NUM_SELLING_DAYS,
		m3.NUM_DAYS,		
		SI.CAL_DATE,
		SI.CAL_DATE_end,
		SI.CUSTOMER_ID,
		SI.Mrkt_WSE_fit Mrkt_WSE_fit_ori,		
		sum(sum(d.SELLING_DAY)) over (partition by SI.CAL_DATE,SI.CUSTOMER_ID )days_btw_order,
		sum(sum(d.SELLING_DAY)) over (partition by m3.date_init, SI.CAL_DATE,SI.CUSTOMER_ID )days_in_tercio,
		ceiling(isnull(SI.Mrkt_WSE_fit/nullif(sum(sum(d.SELLING_DAY)) over (partition by SI.CAL_DATE,SI.CUSTOMER_ID ),0),0)
											*sum(sum(d.SELLING_DAY)) over (partition by m3.date_init, SI.CAL_DATE,SI.CUSTOMER_ID )) SI_MRKT_WSE

from [STAGING_2].[dbo].XXX_P_Sell_IN_Mrkt_Periods SI
join ite.T_DAY d on d.CAL_DATE between SI.CAL_DATE and	SI.CAL_DATE_end
join [STAGING_2].[dbo].XXX_P_Time_Sell_tercio M3 on (m3.CAL_DATE = d.CAL_DATE)

group by
		m3.tercio,
		m3.date_init,
		m3.date_end,
		m3.NUM_SELLING_DAYS,
		m3.NUM_DAYS,		
		SI.CAL_DATE,
		SI.CAL_DATE_end,
		SI.CUSTOMER_ID,
		SI.Mrkt_WSE_fit
)

select	
		tercio,
		date_init CAL_DATE,
		date_end CAL_DATE_end,
		NUM_SELLING_DAYS,
		NUM_DAYS,
		ceiling(avg(days_btw_order)) days_btw_order,
		ceiling(sum(days_in_tercio)) days_in_tercio,
		CUSTOMER_ID,
		sum(SI_MRKT_WSE) SI_Mrkt_WSE
into [STAGING_2].[dbo].XXX_P_Sell_IN_Mrkt_10d		
from  Sell_IN_Mrkt_10d
group by
		tercio,
		date_init,
		date_end,
		NUM_SELLING_DAYS,
		NUM_DAYS,
		CUSTOMER_ID
	
--order by SI.CUSTOMER_ID, date_init



/*############################## 2 min ########################################*/

IF OBJECT_ID('[STAGING_2].[dbo].XXX_P_Sell_IN_Periods_10d', 'U') IS NOT NULL
 DROP TABLE [STAGING_2].[dbo].XXX_P_Sell_IN_Periods_10d;


select	RANK() over (partition by i.CUSTOMER_ID,i.BRANDFAMILY_ID order by i.CAL_DATE)-1 R,
		i.tercio,
		i.CAL_DATE,
		i.CAL_DATE_end,
		i.NUM_SELLING_DAYS,
		i.NUM_DAYS,
		i.days_btw_order,
		i.days_in_tercio,
		i.CUSTOMER_ID,
		i.BRANDFAMILY_ID,
		i.SI_ITG_WSE,
		sum(SI_Mrkt_WSE_adjust) over (partition by i.CUSTOMER_ID, i.CAL_DATE) SI_Mrkt_WSE_adjust,
		case when m.SI_Mrkt_WSE< sum(i.SI_ITG_WSE) over (partition by i.CUSTOMER_ID, i.CAL_DATE)  then sum(i.SI_ITG_WSE) over (partition by i.CUSTOMER_ID, i.CAL_DATE)  else m.SI_Mrkt_WSE end + 
			case when sum(SI_Mrkt_WSE_adjust) over (partition by i.CUSTOMER_ID, i.CAL_DATE) + m.SI_Mrkt_WSE  < sum(i.SI_ITG_WSE) over (partition by i.CUSTOMER_ID, i.CAL_DATE)  then 0 else sum(SI_Mrkt_WSE_adjust) over (partition by i.CUSTOMER_ID, i.CAL_DATE) end SI_Mrkt_WSE
into [STAGING_2].[dbo].XXX_P_Sell_IN_Periods_10d		
from  [STAGING_2].[dbo].XXX_P_Sell_IN_ITG_10d I join [STAGING_2].[dbo].XXX_P_Sell_IN_Mrkt_10d m
  on i.CUSTOMER_ID=m.CUSTOMER_ID and
     i.CAL_DATE=m.CAL_DATE


;
SET @t2 = GETDATE();
SELECT '03.P_ITG_SELL_IN_10d.sql' as SCRIPT,
DATEDIFF(mi,@t1,@t2) AS elapsed_min;