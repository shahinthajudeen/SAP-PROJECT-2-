@EndUserText.label: 'Product Inventory Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true  
define root view entity ZC_ProductInventory
  provider contract transactional_query
  as projection on ZI_ProductInventory
{
  key ProductId,
  ProductName,
  Category,
  Quantity,
  Price,
  Currency,
  Supplier,
  CreatedAt,
  UpdatedAt
}
