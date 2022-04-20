/***********   12 min *****************/
-- OUTPUT: [STAGING_2].[dbo].XXX_P_Sell_IN_ITG_Periods
--		[STAGING_2].[dbo].XXX_P_sacas_periods
--		XXX_P_ITG_Sell_IN_top

-- INPUT:
--		[ITE_PRD].[ITE].FACT_SMLD_Smoke_ITG
--			[ITE_PRD].[ITE].T_DAY
--			[ITE_PRD].[ITE].T_BRANDPACKS
--		[ITE_PRD].[ITE].[FactLess_CALENDARIO_SACA]


-- [STAGING_2].[dbo].XXX_P_Sell_IN_ITG_std

/*  RESULT: Datos ventas SellIn 
   [STAGING_2].[dbo].XXX_P_Sell_IN_ITG --> Sell In Positivos, ventas base
   [STAGING_2].[dbo].XXX_P_Sell_IN_ITG_neg --> Sell In Negativos, determina Familias&Clitentes a arreglar
   [STAGING_2].[dbo].XXX_P_Sell_IN_ITG_Periods -->Sell In de estancos SIN Sell Out, arreglados los negativos, y agrupados por pedidos.
*/

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

IF OBJECT_ID('[STAGING_2].[dbo].XXX_P_sacas_periods', 'U') IS NOT NULL
 DROP TABLE [STAGING_2].[dbo].XXX_P_sacas_periods;

with Sacas as (
	select distinct Customer_id, 
				SalesDate SacaDIA, 
				convert(date, convert(varchar(8),SalesDate),112) SacaDate,
				r = row_number() over (partition by [CUSTOMER_ID] order by SalesDate desc)
	from [ITE_PRD].[ITE].[FactLess_CALENDARIO_SACA]
	where isnull(SalesDate,0)<>0 and SalesDate >= 20170401 --and convert(int, convert(varchar(8),GETDATE()-1,112))
	)
 

select s.r, s.Customer_id, s.SacaDIA, n.SacaDIA nextSacaDIA, s.SacaDate, n.SacaDate nextSacaDate
into [STAGING_2].[dbo].XXX_P_sacas_periods
from Sacas s
	join	Sacas n
	on   s.[CUSTOMER_ID] = n.[CUSTOMER_ID] and
		 s.r = n.r + 1




/*#########################################################################*/


IF OBJECT_ID('[STAGING_2].[dbo].XXX_P_Sell_IN_ITG', 'U') IS NOT NULL
 DROP TABLE [STAGING_2].[dbo].XXX_P_Sell_IN_ITG;
 
select	
	a12.CAL_DATE,
	a11.[CUSTOMER_ID]  CUSTOMER_ID,
	a15.[BRANDFAMILY_ID]  BRANDFAMILY_ID,
--	a15.SUBCATEGORY  Midcategory,
	sum(a11.[VOL_EQUI])  SI_WSE
into [STAGING_2].[dbo].XXX_P_Sell_IN_ITG
from	ITE.FACT_SMLD_Smoke_ITG	a11
	join	ITE.T_DAY	a12
	  on 	(a11.[SALESDATE] = a12.[CAL_DAY])
	join	ITE.T_BRANDPACKS	a15
	  on 	(a11.[BRANDPACK_ID] = a15.[BRANDPACK_ID] )
where	a12.CAL_MONTH >=  '201704' /*and
 not exists (select 1 from   ITE.V_Lu_Muestra_SO_1Canal_15M SO 
				   where  SO.[Muestra_so_ok]=1 and 
				   a11.CUSTOMER_ID 	= SO.CUSTOMER_ID )*/
 and a15.SUBCATEGORY in (N'BLOND', N'RYO')
 and a11.[VOL_EQUI] > 0
group by	CAL_DATE,
	a11.[CUSTOMER_ID],
	a15.[BRANDFAMILY_ID]
--	a15.SUBCATEGORY

	
/*#########################################################################*/
IF OBJECT_ID('[STAGING_2].[dbo].XXX_P_Sell_IN_ITG_neg', 'U') IS NOT NULL
 DROP TABLE [STAGING_2].[dbo].XXX_P_Sell_IN_ITG_neg;
 
select	
	  CAL_DATE,
	a11.[CUSTOMER_ID]  CUSTOMER_ID,
	a15.[BRANDFAMILY_ID]  BRANDFAMILY_ID,
--	a15.SUBCATEGORY  Midcategory,
	ceiling(sum(a11.[VOL_EQUI]))  SI_WSE
into [STAGING_2].[dbo].XXX_P_Sell_IN_ITG_neg
from	ITE.FACT_SMLD_Smoke_ITG	a11
	join	ITE.T_DAY	a12
	  on 	(a11.[SALESDATE] = a12.[CAL_DAY])
	join	ITE.T_BRANDPACKS	a15
	  on 	(a11.[BRANDPACK_ID] = a15.[BRANDPACK_ID] )

where	a12.CAL_MONTH >=  '201704' /*  and
 not exists (select 1 from   ITE.V_Lu_Muestra_SO_1Canal_15M SO 
				   where  SO.[Muestra_so_ok]=1 and 
				   a11.CUSTOMER_ID 	= SO.CUSTOMER_ID ) */
 and a15.SUBCATEGORY in (N'BLOND', N'RYO')
 and a11.[VOL_EQUI] < 0
group by	CAL_DATE,
	a11.[CUSTOMER_ID],
	a15.[BRANDFAMILY_ID]
--	a15.SUBCATEGORY



/*################################ ?? min #####################################*/
IF OBJECT_ID('[STAGING_2].[dbo].XXX_P_Sell_IN_ITG_std', 'U') IS NOT NULL
 DROP TABLE [STAGING_2].[dbo].XXX_P_Sell_IN_ITG_std;
 
 

			
		select  CUSTOMER_ID,
				BRANDFAMILY_ID,
				Date_Start,Date_End,
				ceiling(SI_WSE) SI_WSE_median,
				HI,std, mean
		into [STAGING_2].[dbo].XXX_P_Sell_IN_ITG_std
		from (
			select t.*, --n.CAL_DATE,n.SI_WSE,
						
				pos = row_number() over (partition by t.[CUSTOMER_ID], t.[BRANDFAMILY_ID], n.CAL_DATE order by t.SI_WSE) ,
				ceiling(max(t.SI_WSE) over (partition by  t.[CUSTOMER_ID], t.[BRANDFAMILY_ID],n.CAL_DATE)) HI,
				ceiling(0.5* count(*) over (partition by  t.[CUSTOMER_ID], t.[BRANDFAMILY_ID],n.CAL_DATE)) median_pos,
				ceiling(STDEV(t.SI_WSE) over (partition by  t.[CUSTOMER_ID], t.[BRANDFAMILY_ID],n.CAL_DATE)) std,
				ceiling(avg(t.SI_WSE) over (partition by  t.[CUSTOMER_ID], t.[BRANDFAMILY_ID],n.CAL_DATE)) mean,
				min(t.CAL_DATE) over (partition by  t.[CUSTOMER_ID], t.[BRANDFAMILY_ID],n.CAL_DATE) Date_Start,
				max(t.CAL_DATE) over (partition by  t.[CUSTOMER_ID], t.[BRANDFAMILY_ID],n.CAL_DATE) Date_End
			from [STAGING_2].[dbo].XXX_P_Sell_IN_ITG t
			 join [STAGING_2].[dbo].XXX_P_Sell_IN_ITG_neg n 
				   on t.[CUSTOMER_ID]=n.[CUSTOMER_ID] and  
					  t.[BRANDFAMILY_ID]= n.[BRANDFAMILY_ID] and
					  n.CAL_DATE > t.CAL_DATE and
					  n.CAL_DATE < dateadd(m,2,t.CAL_DATE)
		) a
		where pos= median_pos	


 




/*################################ ?? min #####################################*/
IF OBJECT_ID('[STAGING_2].[dbo].XXX_P_ITG_Sell_IN_top', 'U') IS NOT NULL
 DROP TABLE [STAGING_2].[dbo].XXX_P_ITG_Sell_IN_top;

/*### Normalizacion de Ventas negativas: 
Una venta negativa se elimina y 
provoca que la venta mas alta de los ultimos 2 meses 
se sustituya por la mediana */

with  ITG_Sell_IN_adjust as (
select  --t.r R,
	t.CAL_DATE,--p.CAL_DATE CAL_DATE_end,
	t.[CUSTOMER_ID],
	t.[BRANDFAMILY_ID],
--	t.Midcategory,
	ceiling( t.SI_WSE) SI_WSE,
	max(case when ceiling( t.SI_WSE) = s.HI then SI_WSE_median else t.SI_WSE end) SI_WSE_adjust,
	max(s.SI_WSE_median) SI_WSE_median, 
	s.HI, 
	avg(s.std) std, avg(s.mean) mean
--into [STAGING_2].[dbo].XXX_P_Sell_IN_ITG_Periods
from  [STAGING_2].[dbo].XXX_P_Sell_IN_ITG t	      
left join [STAGING_2].[dbo].XXX_P_Sell_IN_ITG_std  s
	   on --n.CAL_DATE is not null and 
		  t.[CUSTOMER_ID]=s.[CUSTOMER_ID] and  
	      t.[BRANDFAMILY_ID]= s.[BRANDFAMILY_ID] and
	      t.CAL_DATE between Date_Start and Date_End
group by-- t.r ,
	t.CAL_DATE,--p.CAL_DATE,
	t.[CUSTOMER_ID],
	t.[BRANDFAMILY_ID],
--	t.Midcategory,
	ceiling(t.SI_WSE) ,
	s.HI
)


, ITG_Sell_IN_sacas as (
Select
	p.SacaDate CAL_DATE,
	s.CUSTOMER_ID,
	s.BRANDFAMILY_ID,
--	s.Midcategory,
	sum(s.SI_WSE_adjust - s.SI_WSE) SI_MRKT_adjust,
	sum(s.SI_WSE_adjust) SI_ITG_WSE
from ITG_Sell_IN_adjust s
join [STAGING_2].[dbo].XXX_P_sacas_periods p
   on (s.CUSTOMER_ID = p.CUSTOMER_ID and
		s.CAL_DATE >= p.SacaDate and 
		s.CAL_DATE < p.nextSacaDate)
group by
	p.SacaDate,
	s.CUSTOMER_ID,
	s.BRANDFAMILY_ID
--	s.Midcategory
)



select *, r = row_number() over (partition by [CUSTOMER_ID], [BRANDFAMILY_ID] order by CAL_DATE desc), 
		COUNT( CAL_DATE) over (partition by [CUSTOMER_ID], [BRANDFAMILY_ID]) num
into [STAGING_2].[dbo].XXX_P_ITG_Sell_IN_top
from ITG_Sell_IN_sacas




/*###	Agrupacion de Ventas en sacas
Agrupamos todas las ventas sueltas en la saca correspondiente anterior
*/

/*################################ ?? min #####################################*/
IF OBJECT_ID('[STAGING_2].[dbo].XXX_P_Sell_IN_ITG_Periods', 'U') IS NOT NULL
 DROP TABLE [STAGING_2].[dbo].XXX_P_Sell_IN_ITG_Periods;

select  t.r R,
	t.CAL_DATE,dateadd(dd,-1,p.CAL_DATE) CAL_DATE_end,
	t.[CUSTOMER_ID],
	t.[BRANDFAMILY_ID],
--	t.Midcategory,
	ceiling( t.SI_MRKT_adjust) SI_MRKT_adjust,
	ceiling( t.SI_ITG_WSE) SI_ITG_WSE
into [STAGING_2].[dbo].XXX_P_Sell_IN_ITG_Periods
from [STAGING_2].[dbo].XXX_P_ITG_Sell_IN_top t
	join	[STAGING_2].[dbo].XXX_P_ITG_Sell_IN_top p 
	on   t.[CUSTOMER_ID] = p.[CUSTOMER_ID] and
		 t.[BRANDFAMILY_ID] = p.[BRANDFAMILY_ID] and
		 t.r = p.r + 1
group by t.r ,
	t.CAL_DATE,p.CAL_DATE,
	t.[CUSTOMER_ID],
	t.[BRANDFAMILY_ID],
--	t.Midcategory,
	ceiling(t.SI_ITG_WSE),
	ceiling( t.SI_MRKT_adjust)
	            
 order by 	t.CUSTOMER_ID,	t.BRANDFAMILY_ID, t.CAL_DATE
;
SET @t2 = GETDATE();
SELECT '01.P_ITG_SELL_IN.sql' as SCRIPT,
DATEDIFF(mi,@t1,@t2) AS elapsed_min;