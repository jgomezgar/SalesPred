/*###########################  1 min ##########################################*/
--OUTPUT: [STAGING_2].[dbo].XXX_P_TOTAL_Sell_INOUT_Activities_10d

--INPUT: [STAGING_2].[dbo].[XXX_P_Sell_INOUT_Activities_10d]

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
IF OBJECT_ID('[STAGING_2].[dbo].XXX_P_TOTAL_Sell_INOUT_Activities_10d', 'U') IS NOT NULL
 DROP TABLE [STAGING_2].[dbo].XXX_P_TOTAL_Sell_INOUT_Activities_10d;

SELECT [R] = row_number() over (partition by c0.[CUSTOMER_ID] order by [CAL_DATE] ) -1 ,
      [tercio],
      [NUM_SELLING_DAYS],
      [NUM_DAYS],
      ceiling(min(1.0*[days_btw_order])) [days_btw_order],
      ceiling(avg(1.0*[num_orders])) [num_orders],
      [CAL_DATE],
      [CAL_DATE_end],
      c0.[CUSTOMER_ID],
      'ITG-TOTAL' [BRANDFAMILY_ID],
    --  ,[Midcategory]
        sum([SI_ITG_WSE]) [SI_ITG_WSE],
		[SI_MRKT_WSE] ,
		sum([QUOTA_SELLIN] ) [QUOTA_SELLIN] ,
		sum(SO_ITG_WSE) SO_ITG_WSE,
        [SO_MRKT_WSE],
        sum(QUOTA_SELLOUT) QUOTA_SELLOUT,
		sum([MECHERO] ) [MECHERO] ,
		sum([CLIPPER] ) [CLIPPER] ,
		sum([ABP] ) [ABP] ,
		sum([DISPENSADOR] ) [DISPENSADOR] ,
		sum([VISIBILIDAD] ) [VISIBILIDAD] ,
		sum([VISIBILIDAD_ESP] ) [VISIBILIDAD_ESP] ,
		sum([AZAFATA] ) [AZAFATA] ,
		sum([TOTEM] ) [TOTEM] ,
		sum([TOTEM_ESP] ) [TOTEM_ESP] ,
		sum([SVM] ) [SVM] ,
		sum([TFT] ) [TFT] ,
		avg([CUE] ) [CUE] ,
		avg([visit] ) [visit] ,
		sum([PERC_MECHERO] ) [PERC_MECHERO] ,
		sum([PERC_CLIPPER] ) [PERC_CLIPPER] ,
		sum([PERC_ABP] ) [PERC_ABP] ,
		sum([PERC_DISPENSADOR] ) [PERC_DISPENSADOR] ,
		sum([PERC_VISIBILIDAD] ) [PERC_VISIBILIDAD] ,
		sum([PERC_VISIBILIDAD_ESP] ) [PERC_VISIBILIDAD_ESP] ,
		sum([PERC_AZAFATA] ) [PERC_AZAFATA] ,
		sum([PERC_TOTEM] ) [PERC_TOTEM] ,
		sum([PERC_TOTEM_ESP] ) [PERC_TOTEM_ESP] ,
		sum([PERC_SVM] ) [PERC_SVM] ,
		sum([PERC_TFT] ) [PERC_TFT] ,
		avg([PERC_CUE] ) [PERC_CUE] ,
		avg([PERC_visit] ) [PERC_visit]
	into [STAGING_2].[dbo].XXX_P_TOTAL_Sell_INOUT_Activities_10d	
  FROM [STAGING_2].[dbo].[XXX_P_Sell_INOUT_Activities_10d] c0
--join ITE.LU_CLTE_1CANAL	a11 on a11.customer_id = c0.customer_id

/*where	a11.[Siebel_Segment] in (N'DOM')
  
and c0.brandFamily_id in ('BF231021',
							'BF234104',
							'BF231048',
							'BF234103',
							'BF241049',
							'BF241151')
*/
group by
	  [tercio],
      [NUM_SELLING_DAYS],
      [NUM_DAYS],
      [CAL_DATE],
      [CAL_DATE_end],
      c0.[CUSTOMER_ID],
      [SI_MRKT_WSE],
      [SO_MRKT_WSE]
      
;
SET @t2 = GETDATE();
SELECT '07.P_TOTAL_Sell_INOUT_Activities_10d.sql' as SCRIPT,
 DATEDIFF(mi,@t1,@t2) AS elapsed_min;