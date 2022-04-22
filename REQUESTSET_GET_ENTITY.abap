  method requestset_get_entity.
    types: begin of ty_open_requests_tt,
             posting_date type crmt_posting_date,
             guid         type crmt_object_guid,
             description  type crmt_process_description,
             object_id    type crmt_object_id_db,
             created_by   type crmt_created_by,
             process_type type crmt_process_type_db,
           end of ty_open_requests_tt.

    data lt_open_requests type standard table of ty_open_requests_tt.

    field-symbols <ls_open_request> like line of lt_open_requests.

    data api_object type ref to cl_ags_crm_1o_api.
    data lv_guid type crmt_object_guid.
    data lv_user_status type crm_j_status.

    data lv_destination_param type char20.

    " Variables and constants for text processing

    types: begin of ty_status_text_tt,
             status_text type j_txt30,
           end of ty_status_text_tt.


    data lt_status_text type standard table of ty_status_text_tt.
    field-symbols <ls_status_text> like line of lt_status_text.

    " Structure for partner search

    data: et_partner         type crmt_partner_external_wrkt,
          ls_partner         type crmt_partner_external_wrk,
          lv_requestor_bp    type bu_partner,
          lv_requestor_uname type crmt_erms_agent_name,
          lv_requestor_id    type uname,
          api_object_sd      type ref to cl_ags_crm_1o_api_sd.

    " Score related variables

    data lv_score type p decimals 2.
    data lv_score_threshold_char(3) type c.
    data lv_score_threshold_low type i.
    data lv_score_threshold_high type i.
    data lv_score_name_param(20) type c.

    " Vendor details

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


    data lv_return_code type sy-subrc.

    data lv_system type c length 3.
    data lv_company_code type c length 10.


    data lv_destination type char256.



    read table it_key_tab into data(ls_scenario_key_tab) with key name = 'guid'.

    lv_guid = ls_scenario_key_tab-value.

    select  posting_date guid description object_id created_by process_type from crmd_orderadm_h into table lt_open_requests
       where guid = lv_guid.


    call method cl_ags_crm_1o_api=>get_instance
      exporting
        iv_header_guid                = lv_guid
        iv_process_mode               = 'C'
      importing
        eo_instance                   = api_object
      exceptions
        invalid_parameter_combination = 1
        error_occurred                = 2
        others                        = 3.

    api_object->get_status( importing ev_user_status = lv_user_status ).

    " Receiving status text

    select txt30 from tj30t into table lt_status_text where estat = lv_user_status and stsma = 'ZMIN0001' and spras = sy-langu.

    loop at lt_status_text assigning <ls_status_text>.

      er_entity-statustext = <ls_status_text>-status_text.

    endloop.

    " Searching for request author

    clear lv_requestor_bp.

    api_object_sd ?= api_object.
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

          er_entity-requestor = lv_requestor_uname.

        endif.  "IF lv_requestor_uname IS NOT INITIAL.


        if lv_requestor_id is not initial.

          er_entity-login = lv_requestor_id.

        endif. " if lv_requestor_id is not initial


      endif. "  IF lv_requestor_bp IS NOT INITIAL.

    endif. "  if et_partner is not initial

    loop at lt_open_requests assigning <ls_open_request>.

      er_entity-postingdate = <ls_open_request>-posting_date.
      er_entity-guid = <ls_open_request>-guid.
      er_entity-description = <ls_open_request>-description.
      er_entity-objectid = <ls_open_request>-object_id.
      er_entity-createdby = <ls_open_request>-created_by.
      er_entity-status = lv_user_status.

      " Setting a flow stage, company code and vendor code

      select single zzfld000007 zzfld00000c zzfld00000d from crmd_customer_h
        into ( er_entity-flowstage, er_entity-vendorcode, er_entity-companycode )
        where guid = <ls_open_request>-guid.


    endloop. " loop at lt_open_requests assigning <ls_open_request>


    select single zzfld00000g from crmd_customer_h into lv_score where guid = <ls_open_request>-guid.

    " Filling score data including text

    er_entity-score = lv_score.

    select single value from zvendunlockparam into lv_score_threshold_char
         where param eq 'SCORE_LOW'.

    lv_score_threshold_low = lv_score_threshold_char.

    select single value from zvendunlockparam into lv_score_threshold_char
        where param eq 'SCORE_HIGH'.

    lv_score_threshold_high = lv_score_threshold_char.

    if ( er_entity-score ge lv_score_threshold_high ).

      lv_score_name_param = 'SCORE_HIGH_NAME'.

    endif.

    if ( er_entity-score < lv_score_threshold_low ).

      lv_score_name_param = 'SCORE_LOW_NAME'.

    endif.

    if ( er_entity-score ge lv_score_threshold_low ) and ( er_entity-score < lv_score_threshold_high ).

      lv_score_name_param = 'SCORE_MIDDLE_NAME'.

    endif.

    select single value from zvendunlockparam into er_entity-scoretext
      where param eq lv_score_name_param.


    " Filling green colour flag

    select single value from zvendunlockparam into lv_score_threshold_char
        where param eq 'SCORE_GREEN_COLOUR'.

    lv_score_threshold_high = lv_score_threshold_char.
    er_entity-scoregreencolour = abap_false.

    if ( er_entity-score ge lv_score_threshold_high ).

      er_entity-scoregreencolour = abap_true.

    endif.


    " Filling vendor details


    select single zzfld00000c from crmd_customer_h into lv_vendor where guid = <ls_open_request>-guid.

    if lv_vendor is not initial.

      " Filling system, company code and score

      select single zzfld000005 zzfld00000d from crmd_customer_h into ( lv_system, lv_company_code ) where guid = <ls_open_request>-guid.

      er_entity-system = lv_system.
      er_entity-companycode = lv_company_code.

      " Getting  RFC destination from setup table

      concatenate lv_system '_RFC_DESTINATION' into lv_destination_param.

      select single value from zvendunlockparam into lv_destination
           where param = lv_destination_param.

      if lv_destination is initial.
        lv_destination = 'SM_SH1CLNT500_READ'.
      endif.

*      select single value from zvendunlockparam into lv_destination
*        where param = 'ERP_RFC_DESTINATION'.
*
*      if lv_destination is initial.
*        lv_destination = 'SM_SH1CLNT500_READ'.
*      endif.

      call function 'ZVENDORS_DATA_PROVIDER' destination lv_destination
        exporting
          ip_mode                     = '1'
          ip_vendor                   = lv_vendor
          ip_bukrs                    = lv_company_code
        importing
          ep_return_code              = lv_return_code
        tables
          et_zvendor_extended_details = lt_zvendor_extended_details.


      if ( lt_zvendor_extended_details is not initial ) and ( lv_return_code = 0 ).

        loop at lt_zvendor_extended_details assigning field-symbol(<ls_zvendor_extended_details>).

          er_entity-vendordatareceived = abap_true.
          er_entity-vendorcode = <ls_zvendor_extended_details>-lifnr.
          er_entity-vendorname = <ls_zvendor_extended_details>-name1.
          er_entity-vendorpostingblock = <ls_zvendor_extended_details>-sperr.
          er_entity-vendortelephone = <ls_zvendor_extended_details>-telf1.
          er_entity-vendortaxnumber = <ls_zvendor_extended_details>-stcd1.
          er_entity-vendorcontactname = <ls_zvendor_extended_details>-cnt_name.
          er_entity-vendorbanknumber = <ls_zvendor_extended_details>-bankl.
          er_entity-vendorbankaccount = <ls_zvendor_extended_details>-bankn.
          er_entity-vendorbankaccountholder = <ls_zvendor_extended_details>-koinh.
          er_entity-vendorpaymentblockreason = <ls_zvendor_extended_details>-textl.
          er_entity-vendorwithholdingtaxtype = <ls_zvendor_extended_details>-witht.
          er_entity-vendoremail = <ls_zvendor_extended_details>-smtp_addr.
          er_entity-vendorpaymenttermskey = <ls_zvendor_extended_details>-zterm.
          er_entity-vendorpaymentmethods = <ls_zvendor_extended_details>-zwels.
          er_entity-vendorreconcillaccount = <ls_zvendor_extended_details>-akont.
          er_entity-vendorbankcountry = <ls_zvendor_extended_details>-banks.
          er_entity-vendorcountrykey = <ls_zvendor_extended_details>-land1.
          er_entity-vendorregion = <ls_zvendor_extended_details>-regio.
          er_entity-vendorcity = <ls_zvendor_extended_details>-ort01.
          er_entity-vendorstreethouse = <ls_zvendor_extended_details>-stras.
          er_entity-vendorpostalcode = <ls_zvendor_extended_details>-pstlz.
          er_entity-companycode = <ls_zvendor_extended_details>-bukrs.
          er_entity-companyname = <ls_zvendor_extended_details>-butxt.

        endloop.

      endif.    " if ( lt_zvendor_extended_details is not initial ) and ( lv_return_code = 0 ).


    endif. " if lv_vendor is not initial.




  endmethod.