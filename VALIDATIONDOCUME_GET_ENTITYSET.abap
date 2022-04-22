  method validationdocume_get_entityset.

    data:   lt_filters type  /iwbep/t_mgw_select_option,
            ls_filter  type  /iwbep/s_mgw_select_option,
            ls_so      type                   /iwbep/s_cod_select_option.
    data ls_entityset like line of et_entityset.

    data lv_guid type crmt_object_guid.

    types: begin of ty_valid_docs_tt,
             param type char20,
             value type char256,
           end of ty_valid_docs_tt.

    data lt_valid_docs type standard table of ty_valid_docs_tt.

    data lv_documents_mask_dec type c length 10.
    data lv_documents_mask_bin type string.
    data lv_docs_counter type integer.
    data lv_iterator type integer.
    data lv_mask_element type char1.
    data lv_mask_length_diff type integer.

    data lv_doc_param_mask type c length 20.
    data lv_doc_number_char type c length 3.

    " First checking filters and then keys
    lt_filters = io_tech_request_context->get_filter( )->get_filter_select_options( ).
    read table lt_filters with table key property = 'GUID' into ls_filter.


    loop at ls_filter-select_options into ls_so.

      lv_guid = ls_so-low.

    endloop.

    if (  lv_guid is initial ).
      read table it_key_tab into data(ls_scenario_key_tab) with key name = 'guid'.
      lv_guid = ls_scenario_key_tab-value.

    endif.

    " Getting documents status mask

    select single zzfld00000e from crmd_customer_h into lv_documents_mask_dec where guid = lv_guid.          .

    " Unpacking documents mask to binary line

    try .
        lv_documents_mask_bin = /ui2/cl_number=>base_converter( number = lv_documents_mask_dec from = 10 to = 2 ).

      catch cx_sy_move_cast_error.
        lv_documents_mask_bin = '00000000000000'.
    endtry.


    " Adding validation documents into the list

    select  param value from zvendunlockparam into table lt_valid_docs
      where param  like 'VALID_DOC_NAME_%'.

    lv_docs_counter = 0.

    loop at lt_valid_docs assigning field-symbol(<ls_valid_docs>).

      translate <ls_valid_docs>-value to lower case.
      translate <ls_valid_docs>-value+0(1) to upper case.

      ls_entityset-documentname = <ls_valid_docs>-value.
      ls_entityset-documentnumber = substring_after( val = <ls_valid_docs>-param sub = 'VALID_DOC_NAME_' ).
      ls_entityset-guid = lv_guid.

      lv_docs_counter = lv_docs_counter + 1.

      " Getting type of a document

      lv_doc_number_char = ls_entityset-documentnumber.

      CONDENSE lv_doc_number_char.

      concatenate 'VALID_DOC_TYPE_' lv_doc_number_char into lv_doc_param_mask.

      select single value from zvendunlockparam into ls_entityset-documenttype
          where param eq lv_doc_param_mask.

      lv_doc_param_mask = ''.

      CONDENSE ls_entityset-documenttype.

      concatenate 'VALID_DOCS_CLASS_' ls_entityset-documenttype into lv_doc_param_mask.

      select single value from zvendunlockparam into ls_entityset-documenttypename
         where param eq lv_doc_param_mask.

      translate ls_entityset-documenttypename to lower case.
      translate ls_entityset-documenttypename+0(1) to upper case.

      append ls_entityset to et_entityset.

    endloop. " loop at lt_valid_docs assigning field-symbol(<ls_valid_docs>).

    "Filling mask up to amount of documents

    lv_mask_length_diff = lv_docs_counter - strlen( lv_documents_mask_bin ).

    if lv_mask_length_diff > 0.
      lv_iterator = 1.
      while lv_iterator le lv_mask_length_diff.

        concatenate '0' lv_documents_mask_bin into lv_documents_mask_bin.
        lv_iterator = lv_iterator + 1.
      endwhile.

    endif. " if lv_mask_length_diff > 0.


    sort et_entityset by documentnumber.

    lv_iterator = 0.

    while lv_iterator < lv_docs_counter.

      lv_mask_element = substring( val = lv_documents_mask_bin off = lv_iterator len = 1 ).

      clear ls_entityset.

      if ( lv_mask_element = '0' or sy-subrc <> 0 ).
        ls_entityset-documentstatus = ''.

      else.
        ls_entityset-documentstatus = 'X'.

      endif. " if ( lv_mask_element = '0' or sy-subrc <> 0 )

      modify et_entityset from ls_entityset transporting documentstatus where documentnumber = ( lv_iterator + 1 ).

      lv_iterator = lv_iterator + 1.

    endwhile.

  endmethod.