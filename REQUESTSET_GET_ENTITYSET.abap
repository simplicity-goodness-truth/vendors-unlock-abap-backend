  method requestset_get_entityset.
    types: begin of ty_open_requests_tt,
             posting_date type crmt_posting_date,
             guid         type crmt_object_guid,
             description  type crmt_process_description,
             object_id    type crmt_object_id_db,
             created_by   type crmt_created_by,
           end of ty_open_requests_tt.

    data lt_open_requests type standard table of ty_open_requests_tt.

    field-symbols <ls_open_request> like line of lt_open_requests.

    data:
      api_object     type ref to cl_ags_crm_1o_api,
      api_object_sd  type ref to cl_ags_crm_1o_api_sd,
      lv_user_status type crm_j_status,
      ls_entityset   like line of et_entityset.

    data lv_destination_param type char20.



    data  lv_user_partner type bu_partner.


    data: et_partner         type crmt_partner_external_wrkt,
          ls_partner         type crmt_partner_external_wrk,
          lv_requestor_bp    type bu_partner,
          lv_requestor_uname type crmt_erms_agent_name,
          lv_requestor_id    type uname,
          lv_requestor_dep   type ad_dprtmnt.

    types: begin of ty_status_text_tt,
             status_text type j_txt30,
           end of ty_status_text_tt.


    data lt_status_text type standard table of ty_status_text_tt.
    field-symbols <ls_status_text> like line of lt_status_text.

    data lv_destination type char256.

    data lv_vendor type lifnr.

    types: begin of ty_zvendor_extended_details_tt,
             lifnr     type char10,
             name1     type char35,
             sperr     type char1,
             telf1     type char16,
             stcd1     type char16,
             land1     type char3,
             regio     type char3,
             ort01     type char25,
             stras     type char30,
             pstlz     type char10,
             smtp_addr type ad_smtpadr,
             zterm     type char4,
             zwels     type char10,
             akont     type char10,
             banks     type char3,
             bankl     type char15,
             bankn     type char18,
             koinh     type char60,
             textl     type char20,
             witht     type char2,
             cnt_name  type char35,
             butxt     type char25,
             bukrs     type char4,
           end of ty_zvendor_extended_details_tt.

    data lt_zvendor_extended_details type standard table of ty_zvendor_extended_details_tt.


*    types: begin of ty_companies_basic_details_tt,
*             bukrs type char4,
*             butxt type char25,
*           end of ty_companies_basic_details_tt.
*
*    data lt_companies_basic_details type standard table of ty_companies_basic_details_tt.


    data lv_return_code type sy-subrc.

    data lv_system type c length 3.
    data lv_company_code type c length 10.

    " Score related variables

    data lv_score type p decimals 2.
    data lv_score_threshold_char(3) type c.
    data lv_score_threshold_low type i.
    data lv_score_threshold_high type i.
    data lv_score_name_param(20) type c.


    read table it_key_tab into data(ls_scenario_key_tab) with key name = 'guid'.


    " Enabling filtering per Object ID
    data(it_filter_so) = io_tech_request_context->get_filter( )->get_filter_select_options( ).

    if line_exists( it_filter_so[ property = 'OBJECTID' ] ).

      data(rg_matnr_so) = it_filter_so[ property = 'OBJECTID' ]-select_options.

*      select posting_date guid description object_id  created_by from crmd_orderadm_h into table lt_open_requests
*          where process_type = 'ZMIN' and object_id in rg_matnr_so and created_by = 'AGS_TQM1'. "and posting_date = sy-datum

      select o~posting_date o~guid description o~object_id o~created_by
        from ( crmd_orderadm_h as o
           inner join crmd_customer_h as c on o~guid = c~guid  )
        into table lt_open_requests
        where o~process_type = 'ZMIN' and c~zzfld000007 = 'U' or c~zzfld000007 = 'Y'
        and o~object_id in rg_matnr_so.

    else.
*      select posting_date guid description object_id  created_by from crmd_orderadm_h into table lt_open_requests
*         where process_type = 'ZMIN' and created_by = 'AGS_TQM1'. "and created_by = '709563'. "and posting_date = sy-datum.


      select o~posting_date o~guid description o~object_id o~created_by
        from ( crmd_orderadm_h as o
                inner join crmd_customer_h as c on o~guid = c~guid  )
       into table lt_open_requests
       where o~process_type = 'ZMIN' and c~zzfld000007 = 'U' or c~zzfld000007 = 'Y'.

    endif.

    " Sorting records by object id
    sort lt_open_requests by object_id descending.

    loop at lt_open_requests assigning <ls_open_request>.

      clear ls_entityset.

      call method cl_ags_crm_1o_api=>get_instance
        exporting
          iv_header_guid                = <ls_open_request>-guid
          iv_process_mode               = 'C'
          iv_process_type               = 'ZMIN'
        importing
          eo_instance                   = api_object
        exceptions
          invalid_parameter_combination = 1
          error_occurred                = 2
          others                        = 3.




      " Searching for request status

      api_object->get_status( importing ev_user_status = lv_user_status ).


      " Skipping WITHDRAWN status E0010

      if ( lv_user_status = 'E0010' ).

        continue.

      endif. " if ( lv_user_status = 'E0010' )

      " Receiving status text

      select txt30 from tj30t into table lt_status_text where estat = lv_user_status and stsma = 'ZMIN0001' and spras = sy-langu.

      loop at lt_status_text assigning <ls_status_text>.

        ls_entityset-statustext = <ls_status_text>-status_text.

      endloop.

      " End of status search

      " Business partners identification

      api_object_sd ?= api_object.

      api_object_sd->get_partners( importing et_partner = et_partner ).

      if et_partner is not initial.

*     " Getting processor and support team from the incident

        loop at et_partner into ls_partner.
          if ls_partner-ref_partner_fct = 'SLFN0004'.
            data(bp_processor) = ls_partner-partner_no.
          endif.
        endloop.

        loop at et_partner into ls_partner.
          if ls_partner-ref_partner_fct = 'SLFN0003'.
            data(bp_supportteam) = ls_partner-partner_no.
          endif.
        endloop.

        " get BP for current user

        call function 'CRM_ERMS_FIND_BP_FOR_USER'
          exporting
            iv_user_id = sy-uname
          importing
            ev_bupa_no = lv_user_partner.

        " get approver partner but000 table if FM giving an error during runtime

        if lv_user_partner is initial.
          select single partner into lv_user_partner from but000 where bu_sort1 = sy-uname.
        endif.

        shift lv_user_partner left deleting leading '0'.


      endif. "    if et_partner is not initial.

      " Searching for request author

      clear lv_requestor_bp.

      api_object_sd->get_partners( importing et_partner = et_partner ).

      if et_partner is not initial.

        loop at et_partner into ls_partner.
          if ls_partner-ref_partner_fct = 'SLFN0002'.
            lv_requestor_bp = ls_partner-partner_no.
          endif.
        endloop.

        if lv_requestor_bp is not initial.

          call function 'CRM_ERMS_FIND_USER_FOR_BP'
            exporting
              ev_bupa_no   = lv_requestor_bp
            importing
              ev_user_name = lv_requestor_uname
              ev_user_id   = lv_requestor_id.

          if lv_requestor_uname is not initial.

            "select single name_textc from user_addr into ls_entityset-requestor where bname = lv_requestor_uname.

            ls_entityset-requestor = lv_requestor_uname.

          endif.  "IF lv_requestor_uname IS NOT INITIAL.

          ls_entityset-login = lv_requestor_id.

          select single department from user_addr into lv_requestor_dep where bname = lv_requestor_id.

          ls_entityset-departament = lv_requestor_dep.

        endif. "  IF lv_requestor_bp IS NOT INITIAL.

      endif. "  if et_partner is not initial

      " End of search for request author







      ls_entityset-postingdate = <ls_open_request>-posting_date.
      ls_entityset-guid = <ls_open_request>-guid.
      ls_entityset-description = <ls_open_request>-description.
      ls_entityset-objectid = <ls_open_request>-object_id.
      ls_entityset-createdby = <ls_open_request>-created_by.
      ls_entityset-status = lv_user_status.


      " Getting flow stage

      select single zzfld000007 from crmd_customer_h into ls_entityset-flowstage where guid = <ls_open_request>-guid.


*
*      select single value from zvendunlockparam into lv_destination
*        where param = 'ERP_RFC_DESTINATION'.
*
*      if lv_destination is initial.
*        lv_destination = 'SM_SH1CLNT500_READ'.
*      endif.

      " Filling vendor details

      select single zzfld00000c from crmd_customer_h into lv_vendor where guid = <ls_open_request>-guid.

      if lv_vendor is not initial.

        " Filling system, company code and score

        select single zzfld000005 zzfld00000d zzfld00000g from crmd_customer_h into ( lv_system, lv_company_code, lv_score ) where guid = <ls_open_request>-guid.

        ls_entityset-system = lv_system.
        ls_entityset-companycode = lv_company_code.

        " Getting  RFC destination from setup table

        concatenate lv_system '_RFC_DESTINATION' into lv_destination_param.

        select single value from zvendunlockparam into lv_destination
             where param = lv_destination_param.

        if lv_destination is initial.
          lv_destination = 'SM_SH1CLNT500_READ'.
        endif.

        " Filling score data including text

        ls_entityset-score = lv_score.

        " Getting thresholds

        select single value from zvendunlockparam into lv_score_threshold_char
            where param eq 'SCORE_LOW'.

        lv_score_threshold_low = lv_score_threshold_char.

        select single value from zvendunlockparam into lv_score_threshold_char
            where param eq 'SCORE_HIGH'.

        lv_score_threshold_high = lv_score_threshold_char.

        if ( ls_entityset-score ge lv_score_threshold_high ).

          lv_score_name_param = 'SCORE_HIGH_NAME'.

        endif.

        if ( ls_entityset-score < lv_score_threshold_low ).

          lv_score_name_param = 'SCORE_LOW_NAME'.

        endif.

        if ( ls_entityset-score ge lv_score_threshold_low ) and ( ls_entityset-score < lv_score_threshold_high ).

          lv_score_name_param = 'SCORE_MIDDLE_NAME'.

        endif.

        select single value from zvendunlockparam into ls_entityset-scoretext
          where param eq lv_score_name_param.

        " Filling green colour flag

        select single value from zvendunlockparam into lv_score_threshold_char
            where param eq 'SCORE_GREEN_COLOUR'.

        lv_score_threshold_high = lv_score_threshold_char.
        ls_entityset-scoregreencolour = abap_false.

        if ( ls_entityset-score ge lv_score_threshold_high ).

          ls_entityset-scoregreencolour = abap_true.

        endif.

        call function 'ZVENDORS_DATA_PROVIDER' destination lv_destination
          exporting
            ip_mode                     = '1'
            ip_vendor                   = lv_vendor
            ip_bukrs                    = lv_company_code
          importing
            ep_return_code              = lv_return_code
          tables
            et_zvendor_extended_details = lt_zvendor_extended_details.

      endif. "   if lv_vendor is not initial.

      if ( lt_zvendor_extended_details is not initial ) and ( lv_return_code = 0 ).

        loop at lt_zvendor_extended_details assigning field-symbol(<ls_zvendor_extended_details>).

          ls_entityset-vendordatareceived = abap_true.
          ls_entityset-vendorcode = <ls_zvendor_extended_details>-lifnr.
          ls_entityset-vendorname = <ls_zvendor_extended_details>-name1.
          ls_entityset-vendorpostingblock = <ls_zvendor_extended_details>-sperr.
          ls_entityset-vendortelephone = <ls_zvendor_extended_details>-telf1.
          ls_entityset-vendortaxnumber = <ls_zvendor_extended_details>-stcd1.
          ls_entityset-vendorcontactname = <ls_zvendor_extended_details>-cnt_name.
          ls_entityset-vendorbanknumber = <ls_zvendor_extended_details>-bankl.
          ls_entityset-vendorbankaccount = <ls_zvendor_extended_details>-bankn.
          ls_entityset-vendorbankaccountholder = <ls_zvendor_extended_details>-koinh.
          ls_entityset-vendorpaymentblockreason = <ls_zvendor_extended_details>-textl.
          ls_entityset-vendorwithholdingtaxtype = <ls_zvendor_extended_details>-witht.
          ls_entityset-vendoremail = <ls_zvendor_extended_details>-smtp_addr.
          ls_entityset-vendorpaymenttermskey = <ls_zvendor_extended_details>-zterm.
          ls_entityset-vendorpaymentmethods = <ls_zvendor_extended_details>-zwels.
          ls_entityset-vendorreconcillaccount = <ls_zvendor_extended_details>-akont.
          ls_entityset-vendorbankcountry = <ls_zvendor_extended_details>-banks.
          ls_entityset-vendorcountrykey = <ls_zvendor_extended_details>-land1.
          ls_entityset-vendorregion = <ls_zvendor_extended_details>-regio.
          ls_entityset-vendorcity = <ls_zvendor_extended_details>-ort01.
          ls_entityset-vendorstreethouse = <ls_zvendor_extended_details>-stras.
          ls_entityset-vendorpostalcode = <ls_zvendor_extended_details>-pstlz.
          ls_entityset-companycode = <ls_zvendor_extended_details>-bukrs.
          ls_entityset-companyname = <ls_zvendor_extended_details>-butxt.

        endloop.

      else.

        ls_entityset-vendordatareceived = abap_false.

      endif. " if ( lt_zvendor_extended_details is not initial ) and ( lv_return_code = 0 ).


*      if ( ls_entityset-companycode is not initial ).
*
*        call function 'ZVENDORS_DATA_PROVIDER' destination lv_destination
*          exporting
*            ip_mode                     = '4'
*            ip_bukrs                    = ls_entityset-companycode
*          importing
*            ep_return_code              = lv_return_code
*          tables
*            et_zcompanies_basic_details = lt_companies_basic_details.
*
*        if ( sy-subrc = 0 ).
*
*          loop at lt_companies_basic_details assigning field-symbol(<ls_companies_basic_details>).
*            ls_entityset-companyname = <ls_companies_basic_details>-butxt.
*          endloop. " loop at lt_companies_basic_details ASSIGNING FIELD-SYMBOL(<ls_companies_basic_details>).
*        endif.
*
*      endif.




      append ls_entityset to et_entityset.


    endloop. " loop at lt_open_requests assigning <ls_open_request>
  endmethod.