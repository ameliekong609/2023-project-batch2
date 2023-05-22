---- THIS TABLE is to assess the Association -----



------------------------------------------------------------------------------
  ---how many vol actually handeld by 3PL for each TPC??
  ----------------------------------------------------------------------------
select sudo_tpc,
sum(convert(float,[order_quantity])) as total_vol
From [Deals_ASX_Analysis].[dbo].TEMP_online_trn_details3
 where trn_date >='2021-01-01' and trn_date <='2021-12-31'    and  [3PL_flg]=1
 group by sudo_tpc


   ----------------------------------------------------------------------------
 --only looking aT CAFA (Cosmetics, Apparel, Footwear, Accessories) Range, WHAT is FREQ and vol look like?? by 3PL?
 --- the purpose is to rank the top X brands. didnt uise the actual Freq and VOl numbers. 
   ----------------------------------------------------------------------------
 select brand,tpc_desc,
 count(distinct  oms_order_no) as total_freq,
sum(convert(float,[order_quantity])) as total_vol

From [Deals_ASX_Analysis].[dbo].TEMP_online_trn_details3
 where trn_date >='2021-01-01' and trn_date <='2021-12-31' and  sudo_tpc in('CM Cosmetics','WW Womenswear','MW Menswear','CH Childrenswear','FO Footwear','AC Accessories') and [3PL_flg]=1
 group by brand,tpc_desc
 order by brand,tpc_desc


 ----------------------------------------------------------------------------
---This is the correct version for vol1 and vol2
 --- this is to find for items fulfiled by 3PL, what are they bundled with??
 --- WE decided to use AR's code for Freq.
 ----------------------------------------------------------------------------
 
select 
t1.[sudo_tpc] as TPC_1,
t1.brand as brand_1,
t2.[sudo_tpc] as TPC_2,
t2.brand as brand_2,
count(distinct  t1.oms_order_no) as total_freq, -- this freq is not USEFUL. we used AR's code 
sum(convert(float,t1.[order_quantity])) as total_vol1, --- THIS IS CORRECT VALUE TO USE/
sum(convert(float,t2.[order_quantity])) as total_vol2  --- THIS IS CORRECT VALUE TO USE/
INTO [Deals_ASX_Analysis].[dbo].TEMP_db_association
from (

select   [oms_order_no],[sudo_tpc],brand,sku_no,order_quantity
From [Deals_ASX_Analysis].[dbo].TEMP_online_trn_details3
 where trn_date >='2021-01-01' and trn_date <='2021-12-31' and sudo_tpc in('CM Cosmetics','WW Womenswear','MW Menswear','CH Childrenswear','FO Footwear','AC Accessories','IA Intimate & Active')  and [3PL_flg]=1 and split_flg=1) t1
 left join 
(
 select   [oms_order_no],[sudo_tpc],brand, sku_no,[order_quantity]
From [Deals_ASX_Analysis].[dbo].TEMP_online_trn_details3
 where trn_date >='2021-01-01' and trn_date <='2021-12-31' and sudo_tpc is not null and split_flg=1  ) t2
  on t1.[oms_order_no]=t2.[oms_order_no]  and t1.sku_no <> t2.sku_no

group by t1.sudo_tpc, t1.brand, t2.sudo_tpc, t2.brand
order by t1.sudo_tpc, t1.brand, t2.sudo_tpc, t2.brand 


 ----------------------------------------------------------------------------
--- to find skus # in Brand Y ------
 ----------------------------------------------------------------------------


 sudo_tpc in('WW Womenswear') and brand in ('Miss Shop', 'Tokito', 'Basque', 'Regatta', 'Only')
 sudo_tpc in('MW Menswear') and brand in ('Reserve', 'Kneji Basics', 'Bonds', 'Blaq', 'Kenji')
 sudo_tpc in('IA Intimate & Active') and brand in ('Bonds', 'Berlei', 'Jockey', 'Chloe & Lola')
 sudo_tpc in('CM Cosmetics') and brand in ('Clinique','Natio', 'M.A.C.', 'The  Ordinary', 'Revlon')
 sudo_tpc in('MW Menswear') and brand in ('Reserve', 'Tommy Hilfiger', 'Maddox', 'Blaq', 'Kenji')
 sudo_tpc in('CH Childrenswear')  and brand in ('Milkshake', 'Spouts', 'Tilii', 'Bauhaus', 'Bonds')
 sudo_tpc in('FO Footwear')   and brand in ('Hush Puppies','Skechers','Converse','Windsor Smith','Verali')
 sudo_tpc in('AC Accessories')  and    brand in ('Piper', 'Miss Shop', 'Gregory Ladner', 'JAG', 'Basque','Trent Nathan')
  sudo_tpc in('MW Menswear') and brand in ('Reserve', 'Kenji Basics', 'Bonds', 'Blaq', 'Kenji')


 select t3.*
 from (
 ----- REPLACE FROM HERE-----------------------------------

 select distinct t2.sku_no,t2.[sudo_tpc],t2.brand, t2.product_type
from (
select distinct  [oms_order_no],[sudo_tpc],brand,sku_no
From [Deals_ASX_Analysis].[dbo].TEMP_online_trn_details3
 where trn_date >='2021-01-01' and trn_date <='2021-12-31' and  sudo_tpc in('AC Accessories')  and    brand in ('Piper', 'Miss Shop', 'Gregory Ladner', 'JAG', 'Basque','Trent Nathan') and [3PL_flg]=1 and split_flg=1) t1
  left join 
(
 select distinct  [oms_order_no],[sudo_tpc],brand, sku_no, product_type
From [Deals_ASX_Analysis].[dbo].TEMP_online_trn_details3
 where trn_date >='2021-01-01' and trn_date <='2021-12-31' and  sudo_tpc in('WW Womenswear') and brand in ('Miss Shop', 'Tokito', 'Basque', 'Regatta','Piper') and split_flg=1) t2
  on t1.[oms_order_no]=t2.[oms_order_no]  and t1.sku_no <> t2.sku_no 

 ----------END OF REPLACEMENT-------------------------------
  ) t3
  left join [Deals_ASX_Analysis].[dbo].TEMP_TOP80SKU3 t4
  on t3.sku_no =t4.sku_no
  where major_fulfilment_type ='Stores'




 