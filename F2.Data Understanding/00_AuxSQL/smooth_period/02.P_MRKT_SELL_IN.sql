/***********   10-15 min *****************/

-- OUTPUT: [STAGING_2].[dbo].XXX_P_Sell_IN_Mrkt_Periods 
-- AUXILIARY OUTPUT:
--		[STAGING_2].[dbo].XXX_P_Sell_IN_Mrkt_fit
--		[STAGING_2].[dbo].XXX_P_Sell_IN_Mrkt_neg
-- INPUT:
--		[ITE_PRD].[ITE].V_FACT_Sales_Target_WSE_Daily
--			[ITE_PRD].[ITE].T_DAY
--			[ITE_PRD].[ITE].T_BRANDPACKS
--		[ITE_PRD].[ITE].[FactLess_CALENDARIO_SACA]

/* 
  [STAGING_2].[dbo].XXX_P_Sell_IN_Mrkt_neg --> Sell In Negativos, determina SubCategoria&Clitentes a arreglar
  [STAGING_2].[dbo].XXX_P_Sell_IN_Mrkt_fit  -->Sell In de estancos SIN Sell Out, arreglados los negativos 
  [STAGING_2].[dbo].XXX_P_Sell_IN_Mrkt_Periods -->Sell In de estancos SIN Sell Out, arreglados los negativos, y agrupados por pedidos.
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
IF OBJECT_ID('[STAGING_2].[dbo].XXX_P_Sell_IN_Mrkt_neg', 'U') IS NOT NULL
 DROP TABLE [STAGING_2].[dbo].XXX_P_Sell_IN_Mrkt_neg;
 
select	
	  CAL_DATE,
	a11.[CUSTOMER_ID]  CUSTOMER_ID,
	a11.[MIDCATEGORY]  ,
	ceiling(sum(a11.[Mrkt_WSE]))  [Mrkt_WSE]
into [STAGING_2].[dbo].XXX_P_Sell_IN_Mrkt_neg
from	[ITE_PRD].[ITE].[V_FACT_Sales_Target_WSE_Daily]	a11
	join	ITE.T_DAY	a12
	  on 	(a11.[DIA] = a12.[DIA])
where	a12.CAL_MONTH >=  '201704' /* and
 not exists (select 1 from   ITE.V_Lu_Muestra_SO_1Canal_15M SO 
				   where  SO.[Muestra_so_ok]=1 and 
				   a11.CUSTOMER_ID 	= SO.CUSTOMER_ID ) */
 and a11.MIDCATEGORY in (N'BLOND', N'BLACK', N'RYO')
 and a11.[Mrkt_WSE] < 0
group by	CAL_DATE,
	a11.[CUSTOMER_ID],
	a11.[MIDCATEGORY]



/*#########################################################################*/
IF OBJECT_ID('[STAGING_2].[dbo].XXX_P_Sell_IN_Mrkt_fit', 'U') IS NOT NULL
 DROP TABLE [STAGING_2].[dbo].XXX_P_Sell_IN_Mrkt_fit;
 


			
with Mrkt_Sell_IN_std as (			
		select  CUSTOMER_ID,
				[MIDCATEGORY],
				Date_Start,Date_End,
				ceiling([Mrkt_WSE]) Mrkt_WSE_median,
				HI,std, mean
		from (
			select	t.DIA,
					t.MIDCATEGORY,
					t.CUSTOMER_ID,
					ceiling(t.ITG_WSE) ITG_WSE,
					ceiling(t.Mrkt_WSE) Mrkt_WSE,
 --n.CAL_DATE,n.SI_WSE,
						
				pos = row_number() over (partition by t.[CUSTOMER_ID], t.[MIDCATEGORY], n.CAL_DATE order by t.[Mrkt_WSE]) ,
				ceiling(max(t.[Mrkt_WSE]) over (partition by  t.[CUSTOMER_ID], t.[MIDCATEGORY],n.CAL_DATE)) HI,
				ceiling(0.5* count(*) over (partition by  t.[CUSTOMER_ID], t.[MIDCATEGORY],n.CAL_DATE)) median_pos,
				ceiling(STDEV(t.[Mrkt_WSE]) over (partition by  t.[CUSTOMER_ID], t.[MIDCATEGORY],n.CAL_DATE)) std,
				ceiling(avg(t.[Mrkt_WSE]) over (partition by  t.[CUSTOMER_ID], t.[MIDCATEGORY],n.CAL_DATE)) mean,
				min(d.CAL_DATE) over (partition by  t.[CUSTOMER_ID], t.[MIDCATEGORY],n.CAL_DATE) Date_Start,
				max(d.CAL_DATE) over (partition by  t.[CUSTOMER_ID], t.[MIDCATEGORY],n.CAL_DATE) Date_End
			from [ITE_PRD].[ITE].[V_FACT_Sales_Target_WSE_Daily] t
				join	ITE.T_DAY	d
				 on 	(t.[DIA] = d.[DIA])
			 join [STAGING_2].[dbo].XXX_P_Sell_IN_Mrkt_neg n 
				   on t.[CUSTOMER_ID]=n.[CUSTOMER_ID] and  
					  t.[MIDCATEGORY]= n.[MIDCATEGORY] and
					  n.CAL_DATE > d.CAL_DATE and
					  n.CAL_DATE < dateadd(m,2,d.CAL_DATE)
			where  t.MIDCATEGORY in (N'BLOND', N'BLACK', N'RYO') and t.[Mrkt_WSE] > 0 and t.DIA >= 20170401
					  
		) a
		where pos= median_pos	
)


/*### Normalizacion de Ventas negativas: 
Una venta negativa se elimina y 
provoca que la venta mas alta de los ultimos 2 meses 
se sustituya por la mediana */


select  --t.r R,
	d.CAL_DATE,--p.CAL_DATE CAL_DATE_end,
	t.[CUSTOMER_ID],
	t.[MIDCATEGORY],
	ceiling( t.[Mrkt_WSE]) [Mrkt_WSE],
	max(case when ceiling( t.[Mrkt_WSE]) = s.HI then Mrkt_WSE_median else ceiling(t.Mrkt_WSE) end) Mrkt_WSE_fit,
	max(s.Mrkt_WSE_median) Mrkt_WSE_median, 
	s.HI, 
	avg(s.std) std, avg(s.mean) mean
into [STAGING_2].[dbo].XXX_P_Sell_IN_Mrkt_fit
from  [ITE_PRD].[ITE].[V_FACT_Sales_Target_WSE_Daily] t
				join	ITE.T_DAY	d
				 on 	(t.[DIA] = d.[DIA])	      
left join Mrkt_Sell_IN_std  s
	   on --n.CAL_DATE is not null and 
		  t.[CUSTOMER_ID]=s.[CUSTOMER_ID] and  
	      t.[MIDCATEGORY]= s.[MIDCATEGORY] and
	      d.CAL_DATE between Date_Start and Date_End
where  t.MIDCATEGORY in (N'BLOND', N'BLACK', N'RYO') and t.[Mrkt_WSE] > 0 and t.DIA >= 20170401
group by-- t.r ,
	d.CAL_DATE,--p.CAL_DATE,
	t.[CUSTOMER_ID],
	t.[MIDCATEGORY],
	ceiling(t.[Mrkt_WSE]) ,
	s.HI



/*#############################################################################*/
IF OBJECT_ID('[STAGING_2].[dbo].XXX_P_Sell_IN_Mrkt_Periods', 'U') IS NOT NULL
 DROP TABLE [STAGING_2].[dbo].XXX_P_Sell_IN_Mrkt_Periods;
 
 

with  Sell_IN_Mrkt_sacas as (
Select
	p.SacaDate CAL_DATE,
	s.CUSTOMER_ID,
--	s.BRANDFAMILY_ID,
--	s.Midcategory,
--	sum(s.SI_WSE_adjust - s.SI_WSE) SI_MRKT_adjust,
	sum(s.Mrkt_WSE_median) Mrkt_WSE_median,
	sum(s.Mrkt_WSE_fit) Mrkt_WSE_fit
from [STAGING_2].[dbo].XXX_P_Sell_IN_Mrkt_fit s
join [STAGING_2].[dbo].XXX_P_sacas_periods p
   on (s.CUSTOMER_ID = p.CUSTOMER_ID and
		s.CAL_DATE >= p.SacaDate and 
		s.CAL_DATE < p.nextSacaDate)
group by
	p.SacaDate,
	s.CUSTOMER_ID
--	s.BRANDFAMILY_ID
--	s.Midcategory
)
,ITG_Sell_IN_top as (

		select *, r = row_number() over (partition by [CUSTOMER_ID] order by CAL_DATE desc), 
		COUNT( CAL_DATE) over (partition by [CUSTOMER_ID]) num
		from Sell_IN_Mrkt_sacas

	)


/*###	Agrupacion de Ventas en sacas
Agrupamos todas las ventas sueltas en la saca correspondiente anterior
*/
select  t.r R,
	t.CAL_DATE,dateadd(dd,-1,p.CAL_DATE) CAL_DATE_end,
	t.[CUSTOMER_ID],
--	t.[BRANDFAMILY_ID],
--	t.Midcategory,
	ceiling( t.Mrkt_WSE_median) Mrkt_WSE_median,
	ceiling( t.Mrkt_WSE_fit) Mrkt_WSE_fit
into [STAGING_2].[dbo].XXX_P_Sell_IN_Mrkt_Periods
from ITG_Sell_IN_top t
	join	ITG_Sell_IN_top p 
	on   t.[CUSTOMER_ID] = p.[CUSTOMER_ID] and
--		 t.[BRANDFAMILY_ID] = p.[BRANDFAMILY_ID] and
		 t.r = p.r + 1
group by t.r ,
	t.CAL_DATE,p.CAL_DATE,
	t.[CUSTOMER_ID],
--	t.[BRANDFAMILY_ID],
--	t.Midcategory,
	ceiling( t.Mrkt_WSE_median),
	ceiling(t.Mrkt_WSE_fit)
	            
 order by 	t.CUSTOMER_ID,	--t.BRANDFAMILY_ID, 
 						t.CAL_DATE


;
SET @t2 = GETDATE();
SELECT '02.P_MRKT_SELL_IN.sql' as SCRIPT,
 DATEDIFF(mi,@t1,@t2) AS elapsed_min;