/*############## OJO WHERE con big 6 */

--- Quality se debe arrastrar desde inicio

with estancosSO as (
select CUSTOMER_ID, so.BRANDFAMILY_ID,MAX(name) name, MIN(SO_DATE) minf, MAX(SO_DATE) maxf, DATEDIFF(M, MIN(SO_DATE), MAX(SO_DATE)) dif 
,DATEDIFF(M, min(MIN(SO_DATE)) over (partition by customer_id), max(MAX(SO_DATE)) over (partition by customer_id)) difcus
from [STAGING_2].[dbo].XXX_Sell_OUT_ITG SO
join ite.T_BRANDFAMILIES b on so.BRANDFAMILY_ID=b.BRANDFAMILY_ID 
--where  BRANDFAMILY_ID in ('BF231048', 'BF241151') and 
--CUSTOMER_ID in ('04030011', '33130485')
where so.brandFamily_id in ( 'BF231021'
							,'BF234104'
							,'BF231048'
							,'BF234103'
							,'BF241049'
							,'BF241151'
							)
group by CUSTOMER_ID, so.BRANDFAMILY_ID
 )
 , lista_ok as(
 select distinct so.CUSTOMER_ID from estancosSO so
 where not exists(
		 select * from estancosSO no_so
		 where not(dif > 5 and difcus > 11)
				and so.CUSTOMER_ID = no_so.CUSTOMER_ID
	)
)

, quality as (
select  a11.[Customer_ID],
case when  a12.[Customer_ID] is null then 0 else 1 end OK_15M
from  ITE.LU_CLTE_1CANAL  a11
  left join  lista_ok  a12
    on   (a11.[Customer_ID] = a12.[Customer_ID])

)

,P_Sell_INOUT_Activities_10d as (
select * from [STAGING_2].[dbo].XXX_P_Sell_INOUT_Activities_10d
/*limited yo top Families*/
where brandFamily_id in ( 'BF231021'
							,'BF234104'
							,'BF231048'
							,'BF234103'
							,'BF241049'
							,'BF241151'
							)
union all
/*TOTAL included*/
select * from [STAGING_2].[dbo].XXX_P_TOTAL_Sell_INOUT_Activities_10d
)


SELECT
  C0.CUSTOMER_ID,
 -- OK_13M,
 -- OK_15M,
  C0.BRANDFAMILY_ID,
 -- C0.Midcategory,
--  m.days_btwn_median,
--  m.days_btwn_mean,
  
    C0.R R,
  C0.tercio           tercio,
  C0.NUM_SELLING_DAYS NUM_SELLING_DAYS,
  C0.NUM_DAYS         NUM_DAYS,
  C0.days_btw_order   days_btw_order,
  C0.num_orders       num_orders,
  C0.CAL_DATE CAL_DATE,
  C0.CAL_DATE_end CAL_DATE_end,
  C0.SI_ITG_WSE SI_ITG_WSE,
  C0.SI_MRKT_WSE SI_MRKT_WSE,
  C0.SO_ITG_WSE SO_ITG_WSE,
  C0.SO_MRKT_WSE SO_MRKT_WSE,
  C0.QUOTA_SELLIN QUOTA_SELLIN,
  C0.QUOTA_SELLOUT QUOTA_SELLOUT,
  C0.MECHERO MECHERO,
  C0.CLIPPER CLIPPER,
  C0.ABP ABP,
  C0.DISPENSADOR DISPENSADOR,
  C0.VISIBILIDAD VISIBILIDAD,
--  C0.VISIBILIDAD_ESP VISIBILIDAD_ESP,
  C0.AZAFATA AZAFATA,
  C0.TOTEM TOTEM,
--  C0.TOTEM_ESP TOTEM_ESP,
  C0.SVM SVM,
  C0.TFT TFT,
  C0.CUE CUE,
  C0.VISIT VISIT,
  C0.PERC_MECHERO PERC_MECHERO,
  C0.PERC_CLIPPER PERC_CLIPPER,
  C0.PERC_ABP PERC_ABP,
  C0.PERC_DISPENSADOR PERC_DISPENSADOR,
  C0.PERC_VISIBILIDAD PERC_VISIBILIDAD,
--  C0.PERC_VISIBILIDAD_ESP PERC_VISIBILIDAD_ESP,
  C0.PERC_AZAFATA PERC_AZAFATA,
  C0.PERC_TOTEM PERC_TOTEM,
--  C0.PERC_TOTEM_ESP PERC_TOTEM_ESP,
  C0.PERC_SVM PERC_SVM,
  C0.PERC_TFT PERC_TFT,
  C0.PERC_CUE PERC_CUE,
  C0.PERC_visit PERC_visit
  



from P_Sell_INOUT_Activities_10d C0

/*left join median m 
  on (C0.CUSTOMER_ID = m.CUSTOMER_ID  and
   C0.BRANDFAMILY_ID = m.BRANDFAMILY_ID ) */
left join quality q 
  on (C0.CUSTOMER_ID = q.CUSTOMER_ID)

where OK_15M = 1 
and C0.QUOTA_SELLIN between 0 and 1
and C0.QUOTA_SELLOUT between 0 and 1
and C0.SO_ITG_WSE >= 0
and C0.SO_MRKT_WSE >= 0

