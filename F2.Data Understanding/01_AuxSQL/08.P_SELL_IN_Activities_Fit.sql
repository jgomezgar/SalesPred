/*############################## 9 min #######################################*/
-- OUTPUT: [STAGING_2].[dbo].[XXX_P_Sell_IN_Activities_10d_fit]
--			[STAGING_2].[dbo].XXX_P_LU_CLTE_Pareto



USE [ITE_PRD]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


DECLARE @t1 DATETIME;
DECLARE @t2 DATETIME;


SET @t1 = GETDATE();
/*#########################################################################*/
IF OBJECT_ID('[STAGING_2].[dbo].[XXX_P_Sell_IN_Activities_10d_fit]', 'U') IS NOT NULL
 DROP TABLE [STAGING_2].[dbo].[XXX_P_Sell_IN_Activities_10d_fit];


with repe as (
SELECT s.R
      ,s.CAL_DATE
      ,s.CAL_DATE_end
      ,s.[tercio]
      ,s.[CUSTOMER_ID]
      ,s.[BRANDFAMILY_ID]
      ,s.SI_MRKT_WSE
      ,s.QUOTA_SELLIN     
      ,case when s.[PERC_MECHERO] > 1 then 3 else ceiling(round(s.[PERC_MECHERO]/3,1)*10) end  [MECHERO]
      ,case when s.[PERC_CLIPPER] > 1 then 3 else ceiling(round(s.[PERC_CLIPPER]/3,1)*10)end [CLIPPER]
      ,case when s.[PERC_ABP] > 1 then 3 else ceiling(round(s.[PERC_ABP]/3,1)*10)end [ABP]
      ,case when ceiling(round(s.PERC_DISPENSADOR*10,0)/3) > 3 then 3 else  ceiling(round(s.PERC_DISPENSADOR*10,0)/3) end DISPENSADOR
      ,case when s.[PERC_VISIBILIDAD] > 3 then 3 when s.[PERC_VISIBILIDAD] < 0.35 then 0 else ceiling(round(s.[PERC_VISIBILIDAD],1)) end  VISIBILIDAD
--      ,case when s.[PERC_VISIBILIDAD_ESP] > 3 then 3 when s.[PERC_VISIBILIDAD_ESP] < 0.35 then 0 else ceiling(round(s.[PERC_VISIBILIDAD_ESP] ,1))end  VISIBILIDAD_ESP
      ,case when s.[AZAFATA] > 3 then 3 else s.[AZAFATA] end [AZAFATA]
      ,case when s.[PERC_TOTEM] > 2 then 2 when s.[PERC_TOTEM] < 0.35 then 0 else ceiling(round(s.[PERC_TOTEM],1)) end  [TOTEM]
--      ,case when s.[PERC_TOTEM_ESP] > 2 then 2 when s.[PERC_TOTEM_ESP] < 0.35 then 0 else ceiling(round(s.[PERC_TOTEM_ESP],1)) end [TOTEM_ESP]
	  ,case when s.[visit] > 3 then 3 else s.[visit] end [visit]
FROM [STAGING_2].[dbo].[XXX_P_Sell_IN_Activities_10d] s 
)


select 
            r.R,
            r.CAL_DATE,
            r.CAL_DATE_end,
            r1.R           R_1,          
            r1.CAL_DATE    CAL_DATE_1,   
            r1.CAL_DATE_end CAL_DATE_end_1,
            r2.R           R_2,          
            r2.CAL_DATE    CAL_DATE_2,   
            r2.CAL_DATE_end CAL_DATE_end_2,
            r.tercio,
            r.[CUSTOMER_ID],
            r.[BRANDFAMILY_ID],
            r.MECHERO,
            r1.MECHERO MECHERO_1,
            r2.MECHERO MECHERO_2,
            ceiling(round(isnull(r.MECHERO,0)*10.0 + isnull(r1.MECHERO,0) *0.666 +isnull(r2.MECHERO,0)*0.334,0)) MECHERO_int,
            r.CLIPPER,
            r1.CLIPPER CLIPPER_1,
            r2.CLIPPER CLIPPER_2,
            ceiling(round(isnull(r.CLIPPER,0)*10.0 + isnull(r1.CLIPPER ,0)*0.666 +isnull(r2.CLIPPER,0)*0.334,0)) CLIPPER_int,

            
            r.ABP,
            r1.ABP ABP_1,
            r2.ABP ABP_2,
            ceiling(round(isnull(r.ABP,0)*10.0 + isnull(r1.ABP ,0)*0.666 +isnull(r2.ABP,0)*0.334,0)) ABP_int,

            r.DISPENSADOR,
            ceiling(round(isnull(r.DISPENSADOR,0)*10.0 + isnull(r1.DISPENSADOR,0) *0.666 +isnull(r2.DISPENSADOR,0)*0.334,0)) DISPENSADOR_int,
            r.VISIBILIDAD,
 --           r.VISIBILIDAD_ESP,
            r.AZAFATA, r1.AZAFATA AZAFATA_1,r2.AZAFATA AZAFATA_2,
            ceiling(round(isnull(r.AZAFATA,0)*10.0 + isnull(r1.AZAFATA,0) *0.666 +isnull(r2.AZAFATA,0)*0.334,0)) AZAFATA_int,
            r.TOTEM,
 --           r.TOTEM_ESP,
            ceiling(round(isnull(r.visit,0)*10.0 + isnull(r1.visit,0) *0.666 +isnull(r2.visit,0)*0.334,0)) visit_int,
            r.SI_MRKT_WSE,
            r.QUOTA_SELLIN,
            total.QUOTA_SELLIN   tot_QUOTA_SELLIN
into [STAGING_2].[dbo].[XXX_P_Sell_IN_Activities_10d_fit]
from repe r
left join repe r1 
      on r.r = r1.r+1 
      and r.[CUSTOMER_ID] = r1.[CUSTOMER_ID]
      and r.[BRANDFAMILY_ID] = r1.[BRANDFAMILY_ID]
left join repe r2 
      on  r.r = r2.r+2
      and r.[CUSTOMER_ID] = r2.[CUSTOMER_ID]
      and r.[BRANDFAMILY_ID] = r2.[BRANDFAMILY_ID]
left join 
[STAGING_2].[dbo].[XXX_P_TOTAL_Sell_IN_Activities_10d] total on 
 r.CAL_DATE = total.CAL_DATE and 
 r.[CUSTOMER_ID] = total.[CUSTOMER_ID] and
 total.[BRANDFAMILY_ID] = 'ITG-TOTAL'
 ;
 

;

 
 

/*#########################################################################*/
IF OBJECT_ID('[STAGING_2].[dbo].[XXX_P_LU_CLTE_Pareto]', 'U') IS NOT NULL
 DROP TABLE [STAGING_2].[dbo].XXX_P_LU_CLTE_Pareto;

 
with  TWeight as (
Select '<150' Tickets, 0.1 TWeight union all
Select '>600', 0.65 union all
Select 'Entre 151 y 250', 0.2 union all
Select 'Entre 201-300', 0.25 union all
Select 'Entre 251 y 350', 0.35 union all
Select 'Entre 301-400', 0.4 union all
Select 'Entre 351 y 400', 0.45 union all
Select 'Entre 401 y 600', 0.50 union all
Select 'Entre 401-500', 0.55 union all
Select 'Más de 500', 0.6 union all
Select 'Menos de 200', 0.15 union all
Select 'N.D.', 0.15
)
, tiket as (
select	 a11.POSTALCODE, a11.CITY, p.PROVINCE_ID, a11.[CUSTOMER_ID]  CUSTOMER_ID,           
	a11.[NAME]  CUSTOMER,                          
	avg(isnull(TWeight,0.15)) TWeight
from	ITE.LU_CLTE_1CANAL	a11      
join ite.T_PROVINCES_TR p on p.PROVINCE_TR_ID=a11.PROVINCE_TR_ID                
	left join	ITE.V_LU_CLTE_1CANAL_Encuestas	a12       
	  on 	(a11.[CUSTOMER_ID] = a12.[CUSTOMER_ID])
	left join TWeight   on a12.[Sold_Tickets_per_day] = TWeight.Tickets
where	a11.[Siebel_Segment] in (N'DOM')	and 
a11.[PROVINCE_TR_ID] not in (N'5100', N'5500', N'5200', N'5600')
 and not (a11.NAME like'%C.P%' or a11.name like'C.I.%' or a11.name like'CI %' or  a11.NAME like'%centro penit%')
group by a11.POSTALCODE, a11.CITY, p.PROVINCE_ID,
	a11.[CUSTOMER_ID] ,           
	a11.[NAME]
	
)

, sales as (
select s.[CUSTOMER_ID], sum(SI_ITG_WSE) SI_ITG_WSE,	SI_MRKT_WSE
 from [STAGING_2].[dbo].XXX_P_Sell_IN_Periods_10d s 
where year(CAL_DATE) = year(getdate())-1
group by s.[CUSTOMER_ID], SI_MRKT_WSE

)


, decil as (
select max(t.POSTALCODE) POSTALCODE, max(t.CITY) CITY, max(t.PROVINCE_ID) PROVINCE_ID, s.[CUSTOMER_ID], 
(2*sum(SI_ITG_WSE)+	sum(SI_MRKT_WSE))* TWeight Weight,
NTILE(100) OVER ( ORDER BY (2*sum(SI_ITG_WSE)+	sum(SI_MRKT_WSE))* TWeight ) decil

 from sales s join tiket t on s.CUSTOMER_ID=t.CUSTOMER_ID
 
group by s.[CUSTOMER_ID],  TWeight
)
/*
select case when decil between 22 and 80 then 2
			when decil >80 then 3
			else 1 end pareto, SUM(Weight)/sum(SUM(Weight))over() w, COUNT(distinct [CUSTOMER_ID]) c
from decil
group by case when decil between 22 and 80 then 2
			when decil > 80 then 3
			else 1 end
order by pareto
*/

select d.POSTALCODE, d.CITY, d.PROVINCE_ID, [CUSTOMER_ID],
	 case when decil between 22 and 80 then 2
			when decil >80 then 3
			else 1 end pareto
into[STAGING_2].[dbo].XXX_P_LU_CLTE_Pareto
from decil d

SET @t2 = GETDATE();
SELECT '08.P_SELL_IN_Activities_Fit.sql' as SCRIPT,
DATEDIFF(mi,@t1,@t2) AS elapsed_min;