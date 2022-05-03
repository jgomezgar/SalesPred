/*################### 10 min #################################################*/
-- OUTPUT: [STAGING_2].[dbo].XXX_P_Sell_IN_Direct_Activities_10d 

-- AUXILIARY OUTPUT:
--		[STAGING_2].[dbo].XXX_P_invest_column
--		[STAGING_2].[dbo].XXX_P_Sell_IN_Direct_Periods_10d_rich_dates_VISITS

-- INPUT:
--		[STAGING_2].[dbo].XXX_P_Sell_IN_Direct_Periods_10d p 
--			[STAGING_2].[dbo].XXX_P_Sell_IN_Direct_ITG s

--		[ITE_PRD].[ITE].[Fact_Invest_Actuals_Daily]
--			[ITE_PRD].[ITE].LU_Invest_Items
--			[ITE_PRD].[ITE].T_BRANDPACKS
--			[ITE_PRD].[ITE].T_DAY

	
--		[ITE_PRD].[ITE].v_FACT_VISITS
--			[ITE_PRD].[ITE].LU_FUERZA_DE_VENTAS

-- INPUT SECUNDARY (MULTIMARCA Translator):
--  		[ITE_PRD].[ITE].LU_CLTE_1CANAL
--	    	[ITE_PRD].[ITE].T_PROVINCES_TR
--	    	[ITE_PRD].[ITE].T_PROVINCES


--		[ITE_PRD].[ITE].Fact_SO_Logista_smld_Custproduct
--			[ITE_PRD].[ITE].T_PRODUCTS
--			[ITE_PRD].[ITE].T_BRANDPACKS
--			[ITE_PRD].[ITE].T_DAY
--			[ITE_PRD].[ITE].fact_conversion_factor

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
IF OBJECT_ID('[STAGING_2].[dbo].XXX_P_invest_column', 'U') IS NOT NULL
 DROP TABLE [STAGING_2].[dbo].XXX_P_invest_column;
 
 
with multimarcaList as (
select 	0 Zona_fortuna_id,'DOM' Siebel_Segment, 'BF234103' BrandFamily_id union all 
select 0, 'DOM',	'BF241049' union all 
select  0, 'DOM',	'BF241151' union all 
select	1 Zona_fortuna_id,'DOM' Siebel_Segment, 'BF234103' BrandFamily_id union all 
select 1, 'DOM',	'BF241049' union all 
select  1, 'DOM',	'BF241151' union all 
select  0 ,'DOM', 'BF234104' union all 
select 1 ,'DOM',	'BF231021' union all
select 0, 'TR 2 BRITANICO', 'BF141002' union all
select 0, 'TR 2 BRITANICO', 'BF132002' union all
select 0, 'TR 2 BRITANICO', 'BF132013' union all
select 0, 'TR 1 FRANCES', 'BF131001' union all
select 0, 'TR 1 FRANCES', 'BF141038' union all
select 0, 'TR 2 BRITANICO', 'BF132005' union all
select 0, 'TR 1 FRANCES', 'BF231084' union all
select 0, 'TR 1 FRANCES', 'BF241061' union all
select 0, 'TR 2 BRITANICO', 'BF234110' union all
select 0, 'TR 2 ALEMAN', 'BF131007' union all
select 0, 'TR 2 MIXTO', 'BF141002' union all
select 0, 'TR 2 MIXTO', 'BF132002' union all
select 0, 'TR 2 MIXTO', 'BF132013' union all
select 0, 'TR 2 MIXTO', 'BF132005' union all
select 0, 'TR 2 MIXTO', 'BF234110' union all
select 1, 'TR 2 BRITANICO', 'BF141002' union all
select 1, 'TR 2 BRITANICO', 'BF132002' union all
select 1, 'TR 2 BRITANICO', 'BF132013' union all
select 1, 'TR 1 FRANCES', 'BF131001' union all
select 1, 'TR 1 FRANCES', 'BF141038' union all
select 1, 'TR 2 BRITANICO', 'BF132005' union all
select 1, 'TR 1 FRANCES', 'BF231084' union all
select 1, 'TR 1 FRANCES', 'BF241061' union all
select 1, 'TR 2 BRITANICO', 'BF234110' union all
select 1, 'TR 2 ALEMAN', 'BF131007' union all
select 1, 'TR 2 MIXTO', 'BF141002' union all
select 1, 'TR 2 MIXTO', 'BF132002' union all
select 1, 'TR 2 MIXTO', 'BF132013' union all
select 1, 'TR 2 MIXTO', 'BF132005' union all
select 1, 'TR 2 MIXTO', 'BF234110' )

, MM as (
select distinct  'BF99999' multi, 4 plex,	a11.[Customer_ID]  Customer_ID, m.BrandFamily_id
from	ITE.LU_CLTE_1CANAL	a11
	join	ITE.T_PROVINCES_TR	a12
	  on 	(a11.[PROVINCE_TR_ID] = a12.[PROVINCE_TR_ID])
	join	ITE.T_PROVINCES	a13
	  on 	(a12.[PROVINCE_ID] = a13.[PROVINCE_ID])
	--join	ITE.LU_SEGM_TURISMO	a14
	--  on 	(Case when substring(a11.[Siebel_Segment],1,2) = 'DO' THEN 'Doméstico' WHEN SUBSTRING(a11.[Siebel_Segment],1,2) = 'TR' THEN 'Travel Retail' ELSE 'ND' END = Case when substring(a14.[SEGM_TURISM_ID],1,2) = 'DO' THEN 'Doméstico' WHEN SUBSTRING(a14.[SEGM_TURISM_ID],1,2) = 'TR' THEN 'Travel Retail' ELSE 'ND' END and 
	--	a11.[Siebel_Segment] = a14.[SEGM_TURISM_ID])
	--ABP packs, Dispensadores item * 40 resto distinc_items
	
	join multimarcaList m
		on m.Zona_fortuna_id = a13.[ZONA_FORTUNA] and
		   m.Siebel_Segment = a11.Siebel_Segment
	   
) 

,invest as (
select	
a15.[CAL_DATE]  CAL_DATE, 
dia_inicio , 
--case when a12.Item_type in ('dispensador') then  convert(int,convert(varchar,dateadd(dd,3,a15.[CAL_DATE]),112)) else  dia_fin end 
dia_fin,
a11.[Customer_ID]  Customer_ID,
case when a13.[BRANDFAMILY_ID] in ('BF999999','BF999998') then MM.BrandFamily_id else a13.BRANDFAMILY_ID end BRANDFAMILY_ID,

upper(case when a12.Item_type not in ('CLIPPER', 'MECHERO', 'AZAFATA', 'TOTEM', 'DISPENSADOR', 'SVM', 'TFT') then
	case when  a11.Investment_type not in ('ABP','Azafatas','CUE') then 'VISIBILIDAD' else a11.Investment_type end 
else a12.Item_type end /*+
	case when a12.[Concepto]<> 'BAU' and a11.Investment_type <> 'ABP' and a12.Item_type not in ( 'dispensador')then '_ESP' else '' end */) Investment,	
   
   
	sum(case 
	    when Item_type in ('dispensador') and (a11.Origen = 'Logista' OR a11.[n_Item] < 5) then a11.[n_Item] * 50 
		when a11.Origen = 'Logista' OR a11.[n_packs] < 200 then isnull(nullif(a11.[n_packs],0), a11.[n_Item])
		else 200  end ) 	[n_packs],
	sum(case when a11.Origen = 'Logista' OR a11.[n_Item] < 3 then a11.[n_Item] else 3  end) [n_Item],
	count(distinct Item_type) distinct_items,
	sum(a11.[coste]) /ISNULL(max(plex),1)   [coste]

	
from [ITE_PRD].[ITE].[Fact_Invest_Actuals_Daily] a11
--	join ITE.V_Lu_Muestra_SO_1Canal_15M  q 
 -- on (a11.CUSTOMER_ID = q.CUSTOMER_ID 
 -- 		and isnull(q.[Muestra_so_ok],0)=0)
	join	ITE.LU_Invest_Items	a12
	  on 	(a11.[Investment_type] = a12.[Investment_type] and 
	         a11.[Item_id] = a12.[Item_id])
	join	ITE.T_BRANDPACKS	a13
	  on 	(a11.[BRANDPACK_ID] = a13.[BRANDPACK_ID])
	join	ITE.T_DAY	a15
	  on 	(a15.[DIA] = dia_inicio )--and dia_fin)	
	left join MM on a11.CUSTOMER_ID = MM.Customer_ID  and 
	CHARINDEX(MM.multi, a13.[BRANDFAMILY_ID]) > 0  
	  
where	
a15.CAL_MONTH  >= '201700' and --para capturar mas TFT/SVM desde 2017
   a13.SUBCATEGORY in (N'BLOND', N'RYO') and a11.Customer_ID is not null
 
group by

a15.[CAL_DATE], 
dia_inicio , 
dia_fin,
a11.[Customer_ID],
case when a13.[BRANDFAMILY_ID] in ('BF999999','BF999998') then MM.BrandFamily_id else a13.BRANDFAMILY_ID end,
upper(case when a12.Item_type not in ('CLIPPER', 'MECHERO', 'AZAFATA', 'TOTEM', 'DISPENSADOR', 'SVM', 'TFT') then
	case when  a11.Investment_type not in ('ABP','Azafatas','CUE') then 'VISIBILIDAD' else a11.Investment_type end 
else a12.Item_type end /*+
	case when a12.[Concepto]<> 'BAU' and a11.Investment_type <> 'ABP' and a12.Item_type not in ( 'dispensador')then '_ESP' else '' end */)
	
)

, invest_clean as (
select 
DIA, d.CAL_DATE,
	Customer_ID,
	BRANDFAMILY_ID,
	Investment,
	case when Investment  in ('TFT','SVM', 'VISIBILIDAD') then distinct_items else 1 end Intensidad
	
 from invest i
 join	ITE.T_DAY	d
   on (d.[DIA] between  dia_inicio  and 
			case when Investment in ('MECHERO','ABP','CLIPPER','DISPENSADOR') then 
					case when convert(int,convert(varchar(8), dateadd(dd, [n_packs]/10, i.CAL_DATE ),112)) > dia_fin then dia_fin else convert(int,convert(varchar(8), dateadd(dd, [n_packs]/10, i.CAL_DATE ),112)) end 
				 when Investment in ('TFT','SVM') then convert(int,convert(varchar(8),GETDATE()-1 ,112))
			 else dia_fin end )
--mantenemos desde 2017 en el join con ventas se eliminará sobrantes			 
--where d.CAL_MONTH  >= '201704'	--and d.CAL_MONTH < convert(varchar(6),GETDATE()-1,112)

) 	



select 	* 
into [STAGING_2].[dbo].XXX_P_invest_column
from invest_clean
	Pivot ( sum(Intensidad) for 
		Investment in (MECHERO, CLIPPER, ABP,DISPENSADOR, VISIBILIDAD, AZAFATA, TOTEM, SVM, TFT, CUE))
	AS tablaPitot





/*#########################################################################*/
IF OBJECT_ID('[STAGING_2].[dbo].XXX_P_Sell_IN_Direct_Periods_10d_rich_dates_VISITS', 'U') IS NOT NULL
 DROP TABLE [STAGING_2].[dbo].XXX_P_Sell_IN_Direct_Periods_10d_rich_dates_VISITS;

with visits as (
select	
	d.[CAL_DATE]  ,
	a11.[Customer_ID],
	1  visit
from	ITE.v_FACT_VISITS	a11
--	join ITE.V_Lu_Muestra_SO_1Canal_15M  q 
--  on (a11.CUSTOMER_ID = q.CUSTOMER_ID 
--  		and isnull(q.[Muestra_so_ok],0)=0)

	join	ITE.LU_FUERZA_DE_VENTAS	a12
	  on 	(a11.[EMP_ID] = a12.[EMP_ID])
	join	ITE.T_DAY	d
	  on 	(a11.[DIA] = d.[DIA])
where	(a11.[DIA] >= 20170400 --and convert(int, convert(varchar(8),GETDATE()-1,112))
 and a12.[POSICION_DESC] not in (N'Blu'))
group by d.[CAL_DATE]  ,
	a11.[Customer_ID]
)


, Sell_Periods_10d_rich_dates as (
-- tiene como objeto enriquecer la informacion acerca del periodo entre compras.
select 
	
	p.tercio,
	p.NUM_SELLING_DAYS,
	p.NUM_DAYS,
	--p.days_btw_order,
	COUNT(distinct s.cal_date) num_orders,
	p.date_init,
	p.date_end,
	p.CUSTOMER_ID,
	p.BRANDFAMILY_ID,
--	p.Midcategory,
	p.SI_ITG_WSE,
	p.SI_MRKT_WSE
from [STAGING_2].[dbo].XXX_P_Sell_IN_direct_Periods_10d p

left join [STAGING_2].[dbo].XXX_P_Sell_IN_Direct_ITG s
		on s.cal_date between p.date_init and p.date_end
		and p.CUSTOMER_ID = s.CUSTOMER_ID
		and p.BRANDFAMILY_ID = s.BRANDFAMILY_ID
	
group by 
	p.tercio,
	p.NUM_SELLING_DAYS,
	p.NUM_DAYS,
--	p.days_btw_order,
	p.date_init, 
	p.date_end,
	p.CUSTOMER_ID,
	p.BRANDFAMILY_ID,
--	p.Midcategory,
	p.SI_ITG_WSE,
	p.SI_MRKT_WSE
)




select 
 -- s.R -1 R,
	s.tercio,
	s.NUM_SELLING_DAYS,
	s.NUM_DAYS,
--	s.days_btw_order,
	s.num_orders,
  s.DATE_init,
  s.DATE_end,
  s.CUSTOMER_ID,
  s.BRANDFAMILY_ID,
--  s.Midcategory,
  isnull(s.SI_ITG_WSE,0) SI_ITG_WSE,
  isnull(s.SI_MRKT_WSE,0) SI_MRKT_WSE,
  isnull(isnull(s.SI_ITG_WSE,0) / nullif(s.SI_MRKT_WSE,0),0) QUOTA_SELLIN,
  sum( isnull(visit,0))          visit     
into [STAGING_2].[dbo].XXX_P_Sell_IN_Direct_Periods_10d_rich_dates_VISITS 
from Sell_Periods_10d_rich_dates s 	
left join visits v  
  on s.CUSTOMER_ID = v.CUSTOMER_ID 
  and v.CAL_DATE between s.DATE_init and s.DATE_end	
 where  S.DATE_init  >= '2017-04-01'	 
group by
  --s.R,
	s.tercio,
	s.NUM_SELLING_DAYS,
	s.NUM_DAYS,
--	s.days_btw_order,
	s.num_orders,
  s.DATE_init,
  s.DATE_end,
  s.CUSTOMER_ID,
  s.BRANDFAMILY_ID,
--  s.Midcategory,
  s.SI_ITG_WSE,
  s.SI_MRKT_WSE
;

/*#########################################################################*/
IF OBJECT_ID('[STAGING_2].[dbo].XXX_P_Sell_IN_Direct_Activities_10d', 'U') IS NOT NULL
 DROP TABLE [STAGING_2].[dbo].XXX_P_Sell_IN_Direct_Activities_10d;

select 
  s.R,
	s.tercio,
	s.NUM_SELLING_DAYS,
	s.NUM_DAYS,
	s.days_btw_order,
	s.num_orders,
  s.DATE_init,
  s.DATE_end,
  s.CUSTOMER_ID,
  s.BRANDFAMILY_ID,
--  s.Midcategory,
  isnull(s.SI_ITG_WSE,0) SI_ITG_WSE,
  isnull(s.SI_MRKT_WSE,0) SI_MRKT_WSE,
  isnull(QUOTA_SELLIN,0) QUOTA_SELLIN,
  sum( isnull(MECHERO,0))        MECHERO,
  sum( isnull(CLIPPER,0))        CLIPPER,
  sum( isnull(ABP,0))            ABP,
  sum( isnull(DISPENSADOR,0))    DISPENSADOR,
  sum( isnull(VISIBILIDAD,0))    VISIBILIDAD,
 -- sum( isnull(VISIBILIDAD_ESP,0))VISIBILIDAD_ESP,
  sum( isnull(AZAFATA,0))        AZAFATA,
  sum( isnull(TOTEM,0))          TOTEM,
 -- sum( isnull(TOTEM_ESP,0))      TOTEM_ESP,
  sum( isnull(SVM,0))            SVM,
  sum( isnull(TFT,0))            TFT,
  sum( isnull(CUE,0))            CUE,
  visit,
  isnull( sum(1.*MECHERO)/nullif(s.NUM_DAYS,0),0) PERC_MECHERO,  
  isnull( sum(1.*CLIPPER)/nullif(s.NUM_DAYS,0),0) PERC_CLIPPER,  
  isnull( sum(1.*ABP)/nullif(s.NUM_DAYS,0),0) PERC_ABP,  
  isnull( sum(1.*DISPENSADOR)/nullif(s.NUM_DAYS,0),0) PERC_DISPENSADOR,  
  isnull( sum(1.*VISIBILIDAD)/nullif(s.NUM_DAYS,0),0) PERC_VISIBILIDAD,  
--  isnull( sum(1.*VISIBILIDAD_ESP)/nullif(s.NUM_DAYS,0),0)PERC_VISIBILIDAD_ESP,
  isnull( sum(1.*AZAFATA)/nullif(s.NUM_DAYS,0),0) PERC_AZAFATA,  
  isnull( sum(1.*TOTEM)/nullif(s.NUM_DAYS,0),0) PERC_TOTEM,  
--  isnull( sum(1.*TOTEM_ESP)/nullif(s.NUM_DAYS,0),0) PERC_TOTEM_ESP,  
  isnull( sum(1.*SVM)/nullif(s.NUM_DAYS,0),0) PERC_SVM,  
  isnull( sum(1.*TFT)/nullif(s.NUM_DAYS,0),0) PERC_TFT,  
  isnull( sum(1.*CUE)/nullif(s.NUM_DAYS,0),0) PERC_CUE,  
  isnull(1.*visit/nullif(s.NUM_DAYS,0),0) PERC_visit
into [STAGING_2].[dbo].XXX_P_Sell_IN_Direct_Activities_10d 
from [STAGING_2].[dbo].XXX_P_Sell_IN_Direct_Periods_10d_rich_dates_VISITS s 
left join [STAGING_2].[dbo].XXX_P_invest_column i
  on s.CUSTOMER_ID = i.CUSTOMER_ID
  and s.BRANDFAMILY_ID = i.BRANDFAMILY_ID
  and i.CAL_DATE between s.DATE_init and s.DATE_end	
where  S.DATE_init  >= '2017-04-01'	 
group by
  s.R,
	s.tercio,
	s.NUM_SELLING_DAYS,
	s.NUM_DAYS,
	s.days_btw_order,
	s.num_orders,
  s.DATE_init,
  s.DATE_end,
  s.CUSTOMER_ID,
  s.BRANDFAMILY_ID,
--  s.Midcategory,
  s.SI_ITG_WSE,
  s.SI_MRKT_WSE,
  s.QUOTA_SELLIN,
  visit
  
  ;
SET @t2 = GETDATE();
SELECT '04.P_SELL_and_ACTIVITIES.sql' as SCRIPT,
DATEDIFF(mi,@t1,@t2) AS elapsed_min;