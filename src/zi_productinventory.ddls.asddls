@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Product Inventory Data Model'
define root view entity ZI_ProductInventory
  as select from zinv_product
{
  key product_id   as ProductId,
  product_name     as ProductName,
  category         as Category,
  quantity         as Quantity,
  
  @Semantics.amount.currencyCode: 'Currency'
  price            as Price,
  currency         as Currency,
  
  supplier         as Supplier,
  created_at       as CreatedAt,
  updated_at       as UpdatedAt
}
