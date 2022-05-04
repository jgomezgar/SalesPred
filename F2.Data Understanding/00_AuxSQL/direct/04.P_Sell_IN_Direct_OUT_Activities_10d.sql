/*############################## 9 min #######################################*/
-- OUTPUT: [STAGING_2].[dbo].XXX_P_Sell_IN_Direct_OUT_Activities_10d

-- AUXILIARY OUTPUT:
--		[STAGING_2].[dbo].XXX_Sell_OUT_ITG

-- INPUT:
--		[STAGING_2].[dbo].[XXX_P_Sell_IN_Direct_Activities_10d]

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
IF OBJECT_ID('[STAGING_2].[dbo].XXX_Sell_OUT_ITG', 'U') IS NOT NULL
 DROP TABLE [STAGING_2].[dbo].XXX_Sell_OUT_ITG;


select	a16.[CAL_DATE] SO_DATE,
	a11.[CUSTOMER_ID]  CUSTOMER_ID,
	a13.[BRANDFAMILY_ID]  BRANDFAMILY_ID,
--	a13.[SUBCATEGORY],
	sum(a11.[Volumen] / a110.[CONVERSION_FACTOR])  SO_WSE,
	min(a16.[CAL_DATE]) over (partition by a11.[CUSTOMER_ID], a13.[BRANDFAMILY_ID] ) SO_Start,
	max(a16.[CAL_DATE]) over (partition by a11.[CUSTOMER_ID], a13.[BRANDFAMILY_ID] ) SO_End
into [STAGING_2].[dbo].XXX_Sell_OUT_ITG
from	ITE_PRD.ITE.Fact_SO_Logista_smld_Custproduct	a11
	join	ITE.T_PRODUCTS	a12
	  on 	(a11.[Product_id] = a12.[Product_id])
	join	ITE.T_BRANDPACKS	a13
	  on 	(a12.[BRANDPACK_ID] = a13.[BRANDPACK_ID])
	join	ITE.T_DAY	a16
	  on 	(a11.[DIA] = a16.[DIA])
	join	ITE.fact_conversion_factor	a110
	  on 	(a13.[CATEGORY] = a110.[CATEGORY] and 
			a13.[EXPANDED] = a110.[EXPANDED] and 
			a13.[PACKTYPE] = a110.[PACKTYPE])
where a16.CAL_MONTH >=  '201704'
  and a13.[SUBCATEGORY] in (N'BLOND', N'RYO')
group by a16.[CAL_DATE],
		 a11.[CUSTOMER_ID],
		 a13.[BRANDFAMILY_ID]
--		 a13.[SUBCATEGORY]
		 
/*############################## 15 min ########################################*/

IF OBJECT_ID('[STAGING_2].[dbo].XXX_P_Sell_IN_Direct_OUT_ITG_Activities_10d', 'U') IS NOT NULL
 DROP TABLE [STAGING_2].[dbo].XXX_P_Sell_IN_Direct_OUT_ITG_Activities_10d;		 
 
SELECT --sia.[R]
       sia.[tercio]
      ,sia.[NUM_SELLING_DAYS]
      ,sia.[NUM_DAYS]
      ,sia.[days_btw_order]
      ,sia.[num_orders]
      ,sia.DATE_init
      ,sia.[DATE_end]
      ,sia.[CUSTOMER_ID]
      ,sia.[BRANDFAMILY_ID]
--      ,sia.[Midcategory]
      ,sia.[SI_ITG_WSE]
      ,sia.[SI_MRKT_WSE]
      ,sia.[QUOTA_SELLIN]
      ,ceiling(SUM( SO.SO_WSE)) SO_ITG_WSE
      ,sia.[MECHERO]
      ,sia.[CLIPPER]
      ,sia.[ABP]
      ,sia.[DISPENSADOR]
      ,sia.[VISIBILIDAD]
--      ,sia.[VISIBILIDAD_ESP]
      ,sia.[AZAFATA]
      ,sia.[TOTEM]
--      ,sia.[TOTEM_ESP]
      ,sia.[SVM]
      ,sia.[TFT]
      ,sia.[CUE]
      ,sia.[visit]
      ,sia.[PERC_MECHERO]
      ,sia.[PERC_CLIPPER]
      ,sia.[PERC_ABP]
      ,sia.[PERC_DISPENSADOR]
      ,sia.[PERC_VISIBILIDAD]
 --     ,sia.[PERC_VISIBILIDAD_ESP]
      ,sia.[PERC_AZAFATA]
      ,sia.[PERC_TOTEM]
--      ,sia.[PERC_TOTEM_ESP]
      ,sia.[PERC_SVM]
      ,sia.[PERC_TFT]
      ,sia.[PERC_CUE]
      ,sia.[PERC_visit]
  into [STAGING_2].[dbo].XXX_P_Sell_IN_Direct_OUT_ITG_Activities_10d
  FROM [STAGING_2].[dbo].[XXX_P_Sell_IN_Direct_Activities_10d] sia
  join [STAGING_2].[dbo].XXX_Sell_OUT_ITG SO 
	   on sia.CUSTOMER_ID 	= SO.CUSTOMER_ID and
		  sia.BRANDFAMILY_ID =	SO.[BRANDFAMILY_ID] and
		  SO_DATE between sia.DATE_init and sia.DATE_end
where  sia.DATE_init between SO_Start and SO_End
GROUP by 
--      sia.[R]
       sia.[tercio]
      ,sia.[NUM_SELLING_DAYS]
      ,sia.[NUM_DAYS]
      ,sia.[days_btw_order]
      ,sia.[num_orders]
      ,sia.DATE_init
      ,sia.[DATE_end]
      ,sia.[CUSTOMER_ID]
      ,sia.[BRANDFAMILY_ID]
--      ,sia.[Midcategory]
      ,sia.[SI_ITG_WSE]
      ,sia.[SI_MRKT_WSE]
      ,sia.[QUOTA_SELLIN]
      ,sia.[MECHERO]
      ,sia.[CLIPPER]
      ,sia.[ABP]
      ,sia.[DISPENSADOR]
      ,sia.[VISIBILIDAD]
 --     ,sia.[VISIBILIDAD_ESP]
      ,sia.[AZAFATA]
      ,sia.[TOTEM]
--      ,sia.[TOTEM_ESP]
      ,sia.[SVM]
      ,sia.[TFT]
      ,sia.[CUE]
      ,sia.[visit]
      ,sia.[PERC_MECHERO]
      ,sia.[PERC_CLIPPER]
      ,sia.[PERC_ABP]
      ,sia.[PERC_DISPENSADOR]
      ,sia.[PERC_VISIBILIDAD]
 --     ,sia.[PERC_VISIBILIDAD_ESP]
      ,sia.[PERC_AZAFATA]
      ,sia.[PERC_TOTEM]
--      ,sia.[PERC_TOTEM_ESP]
      ,sia.[PERC_SVM]
      ,sia.[PERC_TFT]
      ,sia.[PERC_CUE]
      ,sia.[PERC_visit]

/*############################## ? min ########################################*/

IF OBJECT_ID('[STAGING_2].[dbo].XXX_P_Sell_IN_Direct_OUT_Activities_10d', 'U') IS NOT NULL
 DROP TABLE [STAGING_2].[dbo].XXX_P_Sell_IN_Direct_OUT_Activities_10d;		 
		
with MRKT_SO as (
	select	
		a15.[CAL_DATE]  ,
		a11.[CUSTOMER_ID]  ,
	--	a11.[SUBCATEGORY]  Midcategory,
		sum(a11.[WSE_MRKT])  [WSE_MRKT]
	from	ITE.V_Fact_SMLD_WSE_SO_MRKT	a11
		join	ITE.T_DAY	a15
		  on 	(a11.[DIA] = a15.[DIA])
	where	a15.CAL_MONTH >=  '201704'
	  and a11.[SUBCATEGORY] in (N'BLOND', N'RYO')
	group by	a15.[CAL_DATE],
		a11.[CUSTOMER_ID]
	--	a11.[SUBCATEGORY]
)
		
SELECT --sia.[R]
      sia.[tercio]
      ,sia.[NUM_SELLING_DAYS]
      ,sia.[NUM_DAYS]
      ,sia.[days_btw_order]
      ,sia.[num_orders]
      ,sia.[DATE_init]
      ,sia.[DATE_end]
      ,sia.[CUSTOMER_ID]
      ,sia.[BRANDFAMILY_ID]
--      ,sia.[Midcategory]
      ,sia.[SI_ITG_WSE]
      ,sia.[SI_MRKT_WSE]
      ,sia.[QUOTA_SELLIN]
      ,sia.SO_ITG_WSE
      ,ceiling(SUM( SO.[WSE_MRKT])) SO_MRKT_WSE
      ,isnull(SO_ITG_WSE /nullif(SUM( SO.[WSE_MRKT]),0),0) QUOTA_SELLOUT
      ,sia.[MECHERO]
      ,sia.[CLIPPER]
      ,sia.[ABP]
      ,sia.[DISPENSADOR]
      ,sia.[VISIBILIDAD]
 --     ,sia.[VISIBILIDAD_ESP]
      ,sia.[AZAFATA]
      ,sia.[TOTEM]
 --     ,sia.[TOTEM_ESP]
      ,sia.[SVM]
      ,sia.[TFT]
      ,sia.[CUE]
      ,sia.[visit]
      ,sia.[PERC_MECHERO]
      ,sia.[PERC_CLIPPER]
      ,sia.[PERC_ABP]
      ,sia.[PERC_DISPENSADOR]
      ,sia.[PERC_VISIBILIDAD]
  --    ,sia.[PERC_VISIBILIDAD_ESP]
      ,sia.[PERC_AZAFATA]
      ,sia.[PERC_TOTEM]
  --    ,sia.[PERC_TOTEM_ESP]
      ,sia.[PERC_SVM]
      ,sia.[PERC_TFT]
      ,sia.[PERC_CUE]
      ,sia.[PERC_visit]

Into [STAGING_2].[dbo].XXX_P_Sell_IN_Direct_OUT_Activities_10d
 from [STAGING_2].[dbo].XXX_P_Sell_IN_Direct_OUT_ITG_Activities_10d sia
 join MRKT_SO SO 
	   on sia.CUSTOMER_ID 	= SO.CUSTOMER_ID and
	--	  sia.Midcategory =	SO.Midcategory and
		  SO.[CAL_DATE] between sia.[DATE_init] and sia.DATE_end

GROUP by 
--sia.[R]
      sia.[tercio]
      ,sia.[NUM_SELLING_DAYS]
      ,sia.[NUM_DAYS]
      ,sia.[days_btw_order]
      ,sia.[num_orders]
      ,sia.[DATE_init]
      ,sia.[DATE_end]
      ,sia.[CUSTOMER_ID]
      ,sia.[BRANDFAMILY_ID]
--      ,sia.[Midcategory]
      ,sia.[SI_ITG_WSE]
      ,sia.[SI_MRKT_WSE]
      ,sia.[QUOTA_SELLIN]
      ,sia.SO_ITG_WSE
      ,sia.[MECHERO]
      ,sia.[CLIPPER]
      ,sia.[ABP]
      ,sia.[DISPENSADOR]
      ,sia.[VISIBILIDAD]
  --    ,sia.[VISIBILIDAD_ESP]
      ,sia.[AZAFATA]
      ,sia.[TOTEM]
 --     ,sia.[TOTEM_ESP]
      ,sia.[SVM]
      ,sia.[TFT]
      ,sia.[CUE]
      ,sia.[visit]
      ,sia.[PERC_MECHERO]
      ,sia.[PERC_CLIPPER]
      ,sia.[PERC_ABP]
      ,sia.[PERC_DISPENSADOR]
      ,sia.[PERC_VISIBILIDAD]
 --     ,sia.[PERC_VISIBILIDAD_ESP]
      ,sia.[PERC_AZAFATA]
      ,sia.[PERC_TOTEM]
--      ,sia.[PERC_TOTEM_ESP]
      ,sia.[PERC_SVM]
      ,sia.[PERC_TFT]
      ,sia.[PERC_CUE]
      ,sia.[PERC_visit]
order by sia.CUSTOMER_ID,
		sia.BRANDFAMILY_ID,
		sia.[DATE_init] 
;
		
/*############################################################################*/
/*
use [STAGING_2]
go

CREATE NONCLUSTERED INDEX [_dta_index_XXX_P_Sell_IN_Direct_OUT_Activities_10d_8_1952062040__K7_K2_K9_K10_3_4_5_6_8_11_12_13_14_15_16_17_18_19_20_21_22_23_24_25_] ON [dbo].[XXX_P_Sell_IN_Direct_OUT_Activities_10d] 
(
	[CAL_DATE] ASC,
	[tercio] ASC,
	[CUSTOMER_ID] ASC,
	[BRANDFAMILY_ID] ASC
)
INCLUDE ( [NUM_SELLING_DAYS],
[NUM_DAYS],
[days_btw_order],
[num_orders],
[DATE_end],
[SI_ITG_WSE],
[SI_MRKT_WSE],
[QUOTA_SELLIN],
[SO_ITG_WSE],
[SO_MRKT_WSE],
[QUOTA_SELLOUT],
[MECHERO],
[CLIPPER],
[ABP],
[DISPENSADOR],
[VISIBILIDAD],
--[VISIBILIDAD_ESP],
[AZAFATA],
[TOTEM],
--[TOTEM_ESP],
[SVM],
[TFT],
[CUE],
[visit],
[PERC_MECHERO],
[PERC_CLIPPER],
[PERC_ABP],
[PERC_DISPENSADOR],
[PERC_VISIBILIDAD],
--[PERC_VISIBILIDAD_ESP],
[PERC_AZAFATA],
[PERC_TOTEM],
--[PERC_TOTEM_ESP],
[PERC_SVM],
[PERC_TFT],
[PERC_CUE],
[PERC_visit]) WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
go

CREATE STATISTICS [_dta_stat_1952062040_2_9_10] ON [dbo].[XXX_P_Sell_IN_Direct_OUT_Activities_10d]([tercio], [CUSTOMER_ID], [BRANDFAMILY_ID])
go	
*/
SET @t2 = GETDATE();
SELECT '04.P_Sell_IN_Direct_OUT_Activities_10d.sql' as SCRIPT,
DATEDIFF(mi,@t1,@t2) AS elapsed_min;