  method attachments_get_entityset.
    data lv_guid type crmt_object_guid.
*    data api_object type ref to cl_ags_crm_1o_api.
*    data lt_attach_list type ags_t_crm_attachment.
*    field-symbols <ls_attachment> like line of lt_attach_list.


    data:   lt_filters type  /iwbep/t_mgw_select_option,
            ls_filter  type  /iwbep/s_mgw_select_option,
            ls_so      type                   /iwbep/s_cod_select_option.


*    data ls_entityset like line of et_entityset.
*    data lv_fullfname type c length 100.

*    field-symbols <es_entityset> like line of et_entityset.

    " Variables for URL search

*    types : begin of l_typ_instid,
*              instid_a type sibfboriid,
*            end of   l_typ_instid.
*
*
*    data : l_tab_skwg     type standard table of skwg_brel,
*           l_tab_instid   type standard table of l_typ_instid,
*           l_wa_skwg      type skwg_brel,
*           l_tab_loios    type skwf_ios,
*           l_tab_phios    type skwf_ios,
*           l_wa_loios     type skwf_io,
*           l_wa_phios     type skwf_io,
*           l_wa_busobject type sibflporb,
*           lv_url         type saeuri.
*
*    field-symbols : <l_wa_instid> type l_typ_instid,
*                    <l_tab_phios> like line of l_tab_phios.
*
*    types : begin of l_typ_urls,
*              url type saeuri,
*            end of   l_typ_urls.

    " data lt_urls    type standard table of l_typ_urls.

    "data wa_urls like line of lt_urls.

   " data lv_counter type i.

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


    " Start of new method with attachments

    data lt_docs type ict_crm_documents.
    data lt_urls type ict_crm_urls.


    data ls_entity type cl_ai_crm_gw_mymessage_mpc=>ts_attachment.
    if ( lv_guid is not initial ).

      call function 'ICT_READ_ATTACHMENTS'
        exporting
          i_crm_id     = lv_guid
          i_ids_only   = abap_true
        importing
          e_t_document = lt_docs
          e_t_url      = lt_urls.


      loop at lt_docs assigning field-symbol(<docs>).
        ls_entity = cl_ai_crm_gw_attachment=>get_attachment_details_odata( is_abap_doc = <docs> iv_guid = lv_guid ).
        APPEND ls_entity TO et_entityset.
        clear ls_entity.
      endloop.

      describe table et_entityset lines es_response_context-inlinecount.
      SORT et_entityset BY upload_date DESCENDING.

    endif.


    " End of new method with attachments
*
*    call method cl_ags_crm_1o_api=>get_instance
*      exporting
*        iv_header_guid                = lv_guid
*        iv_process_mode               = 'C'
*      importing
*        eo_instance                   = api_object
*      exceptions
*        invalid_parameter_combination = 1
*        error_occurred                = 2
*        others                        = 3.
*
*
*    api_object->get_attachment_list( importing et_attach_list = lt_attach_list ).
*
*
*    loop at lt_attach_list assigning <ls_attachment>.
*
*
*      lv_fullfname = <ls_attachment>-extension.
*
*      translate  lv_fullfname to lower case.
*
*      concatenate <ls_attachment>-file_name '.' lv_fullfname into lv_fullfname.
*
*      ls_entityset-filename = lv_fullfname.
*      ls_entityset-docid = <ls_attachment>-docid.
*      ls_entityset-type = <ls_attachment>-doctype.
*      ls_entityset-class = <ls_attachment>-class.
*      ls_entityset-guid = lv_guid.
*      ls_entityset-changeuser = <ls_attachment>-change_user.
*
*
*      " Converting YYYYMMDD to DD.MM.YYYY
*
*      if <ls_attachment>-change_date is not initial.
*
*        concatenate <ls_attachment>-change_date+6(2) <ls_attachment>-change_date+4(2) <ls_attachment>-change_date(4) into ls_entityset-changedate  separated by '.'.
*
*      endif. " IF <ls_attachment>-change_date IS NOT INITIAL.
*
*      " Finalizing output
*      append ls_entityset to et_entityset.
*
*
*    endloop. " LOOP AT lt_attach_list
*
*
*    " Search for URLs
*
*    append initial line to l_tab_instid assigning <l_wa_instid>.
*    <l_wa_instid>-instid_a = lv_guid.
*
*    select *
*     from skwg_brel
*     into table l_tab_skwg
*     for all entries in l_tab_instid
*     where instid_a = l_tab_instid-instid_a
*     and instid_b like 'L/CRM_L%'.
*
*    sort l_tab_skwg by instid_a typeid_a catid_a.
*
*    delete adjacent duplicates from l_tab_skwg comparing instid_a typeid_a catid_a.
*
*    loop at l_tab_skwg into l_wa_skwg.
*      clear   : l_wa_busobject.
*      refresh : l_tab_loios, l_tab_phios.
*
*      l_wa_busobject-instid = l_wa_skwg-instid_a.
*      l_wa_busobject-typeid = l_wa_skwg-typeid_a.
*      l_wa_busobject-catid  = l_wa_skwg-catid_a .
*
*      call method cl_crm_documents=>get_info
*        exporting
*          business_object = l_wa_busobject
*        importing
*          loios           = l_tab_loios
*          phios           = l_tab_phios.
*
*      lv_counter = 1.
*
*      loop at l_tab_phios assigning <l_tab_phios>.
*        move-corresponding  <l_tab_phios> to l_wa_phios.
*
*        read table l_tab_loios into l_wa_loios index lv_counter.
*
*        call method cl_crm_documents=>get_with_url
*          exporting
*            phio     = l_wa_phios
*            loio     = l_wa_loios
*            url_type = '2'
*          importing
*            url      = lv_url.
*
*        wa_urls-url = lv_url.
*        append wa_urls to lt_urls.
*
*        lv_counter = lv_counter + 1.
*
*      endloop.
*
*    endloop.
*
*
*    lv_counter = 1.
*
*    loop at et_entityset assigning <es_entityset>.
*
*      read table lt_urls into wa_urls index lv_counter.
*
*      <es_entityset>-url = wa_urls.
**
*      modify et_entityset from <es_entityset>.
*
*      lv_counter = lv_counter + 1.
*
*    endloop.
  endmethod.