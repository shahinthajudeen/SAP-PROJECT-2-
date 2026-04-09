" 1. THE BUFFER: Holds data temporarily until the save sequence is triggered
CLASS lcl_buffer DEFINITION.
  PUBLIC SECTION.
    CLASS-DATA: mt_insert TYPE TABLE OF zinv_product,
                mt_update TYPE TABLE OF zinv_product,
                mt_delete TYPE TABLE OF zinv_product.
ENDCLASS.


" 2. THE HANDLER: Validates and moves UI data to the Buffer
CLASS lhc_Product DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Product RESULT result.
    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK Product.
    METHODS read FOR READ
      IMPORTING keys FOR READ Product RESULT result.
    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE Product.
    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE Product.
    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE Product.
ENDCLASS.

CLASS lhc_Product IMPLEMENTATION.
  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  METHOD read.
    LOOP AT keys INTO DATA(ls_key).
      SELECT SINGLE * FROM zinv_product WHERE product_id = @ls_key-ProductId INTO @DATA(ls_db_data).
      IF sy-subrc = 0.
        INSERT VALUE #( ProductId = ls_db_data-product_id
                        ProductName = ls_db_data-product_name
                        Category = ls_db_data-category
                        Quantity = ls_db_data-quantity
                        Price = ls_db_data-price
                        Currency = ls_db_data-currency
                        Supplier = ls_db_data-supplier ) INTO TABLE result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD create.
    DATA lt_insert TYPE TABLE OF zinv_product.

    LOOP AT entities INTO DATA(ls_entity).
      APPEND VALUE #( product_id   = ls_entity-ProductId
                      product_name = ls_entity-ProductName
                      category     = ls_entity-Category
                      quantity     = ls_entity-Quantity
                      price        = ls_entity-Price
                      currency     = ls_entity-Currency
                      supplier     = ls_entity-Supplier ) TO lt_insert.

      INSERT VALUE #( %cid = ls_entity-%cid  ProductId = ls_entity-ProductId ) INTO TABLE mapped-product.
    ENDLOOP.

    " CORRECT WAY: Push to the buffer instead of database
    APPEND LINES OF lt_insert TO lcl_buffer=>mt_insert.
  ENDMETHOD.

  METHOD update.
    DATA lt_update TYPE TABLE OF zinv_product.

    LOOP AT entities INTO DATA(ls_entity).
      SELECT SINGLE * FROM zinv_product WHERE product_id = @ls_entity-ProductId INTO @DATA(ls_db_data).
      IF sy-subrc = 0.
        IF ls_entity-%control-ProductName = if_abap_behv=>mk-on. ls_db_data-product_name = ls_entity-ProductName. ENDIF.
        IF ls_entity-%control-Category = if_abap_behv=>mk-on. ls_db_data-category = ls_entity-Category. ENDIF.
        IF ls_entity-%control-Quantity = if_abap_behv=>mk-on. ls_db_data-quantity = ls_entity-Quantity. ENDIF.
        IF ls_entity-%control-Price = if_abap_behv=>mk-on. ls_db_data-price = ls_entity-Price. ENDIF.
        IF ls_entity-%control-Currency = if_abap_behv=>mk-on. ls_db_data-currency = ls_entity-Currency. ENDIF.
        IF ls_entity-%control-Supplier = if_abap_behv=>mk-on. ls_db_data-supplier = ls_entity-Supplier. ENDIF.
        APPEND ls_db_data TO lt_update.
      ENDIF.
    ENDLOOP.

    " CORRECT WAY: Push to the buffer instead of database
    APPEND LINES OF lt_update TO lcl_buffer=>mt_update.
  ENDMETHOD.

  METHOD delete.
    LOOP AT keys INTO DATA(ls_key).
       APPEND VALUE #( product_id = ls_key-ProductId ) TO lcl_buffer=>mt_delete.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

 " 3. THE SAVER: This framework method is legally allowed to write to the database
CLASS lsc_Product DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS finalize REDEFINITION.
    METHODS check_before_save REDEFINITION.
    METHODS save REDEFINITION.
    METHODS cleanup REDEFINITION.
ENDCLASS.

CLASS lsc_Product IMPLEMENTATION.
  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.
    " Insert records
    IF lcl_buffer=>mt_insert IS NOT INITIAL.
      INSERT zinv_product FROM TABLE @lcl_buffer=>mt_insert.
    ENDIF.

    " Update records
    IF lcl_buffer=>mt_update IS NOT INITIAL.
      UPDATE zinv_product FROM TABLE @lcl_buffer=>mt_update.
    ENDIF.

    " Delete records
    IF lcl_buffer=>mt_delete IS NOT INITIAL.
      LOOP AT lcl_buffer=>mt_delete INTO DATA(ls_delete).
        DELETE FROM zinv_product WHERE product_id = @ls_delete-product_id.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD cleanup.
    " Clear the buffers after save so old data doesn't accidentally get re-saved
    CLEAR: lcl_buffer=>mt_insert, lcl_buffer=>mt_update, lcl_buffer=>mt_delete.
  ENDMETHOD.
ENDCLASS.
