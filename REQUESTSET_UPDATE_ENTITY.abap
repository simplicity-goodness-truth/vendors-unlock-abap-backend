  method requestset_update_entity.

    data lv_action type c length 10.

    data lv_return_code type sy-subrc.
    data lv_status type crm_j_status.
    data lv_new_flow_stage type char1.
    data lv_current_flow_stage type char1.



    data: lt_status type crmt_status_comt,
          ls_status type crmt_status_com.

    data lv_destination type char256.
    data lv_destination_param type char20.
    data lv_documents_mask_dec type c length 10.

    data lv_docs_counter type integer.
    data lv_iterator type integer.
    data ls_header type ihttpnvp.

    data lv_documents_mask_bin type string.

    data lv_mask_length_diff type integer.

    types: begin of ty_valid_docs_tt,
             param type char20,
             value type char256,
           end of ty_valid_docs_tt.

    data lt_valid_docs type standard table of ty_valid_docs_tt.

    types: begin of ty_valid_docs_status_tt,
             document_number type integer,
             document_text   type char256,
             document_status type char1,
             document_type   type integer,
           end of ty_valid_docs_status_tt.

    data lt_valid_docs_status type standard table of ty_valid_docs_status_tt.
    data ls_valid_docs_status type ty_valid_docs_status_tt.
    field-symbols <ls_valid_docs_status> like line of lt_valid_docs_status.
    data lv_doc_param_mask type c length 20.
    data lv_doc_number_char type c length 3.

    data lv_mask_element type char1.

    data lv_guid type crmt_object_guid.
    data lv_object_id type crmt_object_id_db.
    data lv_requestor type c length 100.
    data lv_vendor_code type char10.
    data lv_requestor_id type uname.
    data lv_system type c length 3.
    data lv_company_name type c length 25.
    data lv_company_code type c length 4.
    data: lv_addrnumber type ad_addrnum,
          lv_persnumber type ad_persnum.

    data lv_vendor_name type char35.

    data lv_subject type string.

    field-symbols: <fs_header> type /iwbep/s_mgw_name_value_pair.

    " EMail related variables

    data lv_full_name type ad_namtext.

    "  data lv_subject type so_obj_des.
    data c_newline value cl_abap_char_utilities=>newline.

    " CRM order related variables

    data api_object type ref to cl_ags_crm_1o_api.
    data ev_log_handle_charm type balloghndl.

    data:
      lt_customer_h type table of crmd_customer_h,
      ls_customer_h like line of lt_customer_h.

    " Incident text related variables

    data lv_add_text type string.

    data lv_add_text_line type string.
    data lt_add_text_wrapped type table of swastrtab.

    data: lt_text       type crmt_text_comt,
          ls_text       type crmt_text_com,
          ls_text_line  type tline,
          lt_text_lines type comt_text_lines_t.



    types: begin of ty_prep_text_lines_tt,
             tdline type c length 500,
           end of ty_prep_text_lines_tt.

    data lt_prep_text_lines type standard table of ty_prep_text_lines_tt.


    data lv_comment_text type string.

    data lv_receiver type string.
    data lv_requestor_email type string.


    data:
      lv_mail_msg     type string.


    " Attachments related variables

    data lt_attach_list type ags_t_crm_attachment.
    data lt_del_objects type skwf_ios.
    data ls_del_objects like line of lt_del_objects.
    data lv_files_report type string.


    " Data for scores calculation

    types: begin of ty_docs_classes_tt,
             class_number         type integer,
             class_name           type char256,
             class_count          type integer,
             class_weight         type integer,
             class_elem_weight(5) type p decimals 2,
           end of ty_docs_classes_tt.

    data lt_docs_classes type standard table of ty_docs_classes_tt.
    data ls_docs_classes type ty_docs_classes_tt.

    types: begin of ty_scores_tt,
             class_number            type integer,
             class_score(5)          type p decimals 2,
             class_weighted_score(5) type p decimals 2,
           end of ty_scores_tt.

    data lt_scores type standard table of ty_scores_tt.
    data ls_scores type ty_scores_tt.


    types: begin of ty_valid_docs_param_tt,
             param type char20,
             value type char256,
           end of ty_valid_docs_param_tt.

    data lt_valid_docs_param type standard table of ty_valid_docs_param_tt.
    data lv_class_weight_char type c length 3.


    data lv_score type p decimals 2.
    data lv_final_score type p decimals 2.
    data lv_final_score_char(11) type c.

    data lv_score_threshold_char(3) type c.
    data lv_score_threshold_low type i.
    data lv_score_threshold_high type i.
    data lv_score_name_param(20) type c.
    data lv_score_text  type char256.
    data lv_full_score type char256.

    data wa_zvendunlockqueue type zvendunlockqueue.
    data lv_records_counter type integer.

    data lv_copy_attachments type char1.
    data lv_delete_attachments type char1.

    field-symbols <ls_attachment> like line of lt_attach_list.

    types:
      begin of ty_doclist_tt,
        line(32) type c,
      end of ty_doclist_tt.


    data lt_doclist type standard table of ty_doclist_tt.
    data ls_doclist type ty_doclist_tt.

    data lv_copy_result type sy-subrc.

    types : begin of l_typ_instid,
              instid_a type sibfboriid,
            end of   l_typ_instid.

    data : l_tab_skwg     type standard table of skwg_brel,
           l_tab_instid   type standard table of l_typ_instid,
           l_wa_skwg      type skwg_brel,
           l_wa_busobject type sibflporb.

    data: lv_tab_counter type integer.

    data lt_bin_content     type sdokcntbins.

    data lt_file_access_info type sdokfilacis.
    data ls_file_access_info like line of lt_file_access_info.

    data lt_phioloios       type skwf_lpios.
    data ls_phioloios       like line of lt_phioloios.
    data lt_ios_prop_result type crm_kw_propst.

    data ls_loio            type  skwf_io.
    data ls_phio            type  skwf_io.

    data lv_data_xstr        type xstring.
    data lv_input_length     type i.
    data lv_first_line       type i.
    data lv_last_line         type  i.
    data lv_file             type string.

    data lv_filename type string.
    data lv_extension type char3.

    data ls_bus_objects type sibflporb.

    " data types to support emails from org structure

    data lv_bp_num type realo.

    types: begin of ty_l1_emails_tt,
             email type string,
           end of ty_l1_emails_tt.

    data lt_l1_emails type standard table of ty_l1_emails_tt.
    field-symbols <ls_l1_emails> like line of lt_l1_emails.

    types: begin of ty_l2_emails_tt,
             email type string,
           end of ty_l2_emails_tt.

    data lt_l2_emails type standard table of ty_l2_emails_tt.
    field-symbols <ls_l2_emails> like line of lt_l2_emails.

    " ----------------  Start of implementation ------------------------

    " Getting full URL
    read table me->mr_request_details->technical_request-request_header assigning <fs_header> with key name = '~request_uri'.

    "Getting action from URL

    lv_action = substring_after( val = <fs_header>-value sub = 'Action=' ).

    search lv_action for '&'.

    if ( sy-fdpos > 0 ).

      lv_action = substring_before( val = lv_action sub = '&' ).

    endif. " if ( sy-fdpos > 0 )

    read table it_key_tab into data(ls_scenario_key_tab) with key name = 'guid'.
    lv_guid = ls_scenario_key_tab-value.

    " Picking update payload
    io_data_provider->read_entry_data( importing es_data = er_entity ).

    lv_object_id = er_entity-objectid.
    lv_requestor = er_entity-requestor.
    lv_vendor_code = er_entity-vendorcode.
    lv_vendor_name = er_entity-vendorname.
    lv_requestor_id = er_entity-login.
    lv_system = er_entity-system.
    lv_company_name = er_entity-companyname.
    lv_company_code = er_entity-companycode.
    lv_status = er_entity-status.
    lv_new_flow_stage = er_entity-flowstage.

    " Focusing on specified guid

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

    " Getting processor full name

    select single name_textc from user_addr into lv_full_name where bname = sy-uname.

    " Getting documents mask

    if ( lv_new_flow_stage <> 'G' ) or ( lv_new_flow_stage = 'G' and lv_action = 'Reject' ).

      lv_documents_mask_dec = substring_after( val = <fs_header>-value sub = 'Documents=' ).

    else.


      select single zzfld00000e from crmd_customer_h into lv_documents_mask_dec  where guid = lv_guid.          .


    endif. " if ( lv_new_flow_stage <> 'G' ) or ( lv_new_flow_stage = 'G' and lv_action = 'Reject' ).

    " Unpacking documents mask to binary line

    try .
        lv_documents_mask_bin = /ui2/cl_number=>base_converter( number = lv_documents_mask_dec from = 10 to = 2 ).

      catch cx_sy_move_cast_error.
        lv_documents_mask_bin = '00000000000000'.
    endtry.


    if  ( lv_documents_mask_bin is not initial ) and ( lv_documents_mask_bin <> 0 ).

      " Filling a table of documents and corresponding numbers

      select  param value from zvendunlockparam into table lt_valid_docs
          where param like 'VALID_DOC_NAME_%'.

      lv_docs_counter = 0.

      loop at lt_valid_docs assigning field-symbol(<ls_valid_docs>).

        ls_valid_docs_status-document_number = substring_after( val = <ls_valid_docs>-param sub = 'VALID_DOC_NAME_' ).
        ls_valid_docs_status-document_text = <ls_valid_docs>-value.

        " Adding a type of a document
        lv_doc_number_char = ls_valid_docs_status-document_number.
        condense lv_doc_number_char.

        concatenate 'VALID_DOC_TYPE_' lv_doc_number_char into lv_doc_param_mask.

        select single value from zvendunlockparam into lv_doc_number_char
          where param eq lv_doc_param_mask.

        ls_valid_docs_status-document_type = lv_doc_number_char .

        append ls_valid_docs_status to lt_valid_docs_status.

        lv_docs_counter = lv_docs_counter + 1.

      endloop. " loop at lt_valid_docs assigning field-symbol(<ls_valid_docs>).

      sort lt_valid_docs_status by document_number.

      "Filling mask up to amount of documents

      lv_mask_length_diff = lv_docs_counter - strlen( lv_documents_mask_bin ).

      if lv_mask_length_diff > 0.
        lv_iterator = 1.
        while lv_iterator le lv_mask_length_diff.

          concatenate '0' lv_documents_mask_bin into lv_documents_mask_bin.
          lv_iterator = lv_iterator + 1.
        endwhile.

      endif. " if lv_mask_length_diff > 0.

      lv_iterator = 0.
      clear ls_valid_docs_status.

      while lv_iterator < lv_docs_counter.

        lv_mask_element = substring( val = lv_documents_mask_bin off = lv_iterator len = 1 ).

        clear ls_valid_docs_status.

        if ( lv_mask_element = '0' or sy-subrc <> 0 ).
          ls_valid_docs_status-document_status = ''.

        else.
          ls_valid_docs_status-document_status = 'X'.

        endif. " if ( lv_mask_element = '0' or sy-subrc <> 0 )

        modify lt_valid_docs_status from ls_valid_docs_status transporting document_status where document_number = ( lv_iterator + 1 ).

        lv_iterator = lv_iterator + 1.

      endwhile.


    endif. " if  ( lv_documents_mask_bin is not initial ) and ( lv_documents_mask_bin <> 0 ).


    " ------------------  Score calculation  -----------------------------

    if ( lv_new_flow_stage <> 'G' ).

      " Preparing a table of document classes with weights and document count

      select param value from zvendunlockparam into table lt_valid_docs_param
        where param  like 'VALID_DOCS_CLASS_%'.

      loop at lt_valid_docs_param assigning field-symbol(<ls_valid_docs_param>).

        lv_doc_number_char = substring_after( val = <ls_valid_docs_param>-param sub = 'VALID_DOCS_CLASS_' ).
        ls_docs_classes-class_number = lv_doc_number_char.
        ls_docs_classes-class_name = <ls_valid_docs_param>-value.

        lv_doc_number_char = ls_docs_classes-class_number.

        condense lv_doc_number_char.

        concatenate 'VALID_DOCS_WEIGHT_' lv_doc_number_char  into lv_doc_param_mask.

        select single value from zvendunlockparam into lv_class_weight_char
           where param eq lv_doc_param_mask.

        ls_docs_classes-class_weight = lv_class_weight_char.

        lv_doc_number_char = ls_docs_classes-class_number.

        condense lv_doc_number_char.

        select count(*) from zvendunlockparam into ls_docs_classes-class_count
           where param like 'VALID_DOC_TYPE_%' and value eq lv_doc_number_char.

        ls_docs_classes-class_elem_weight = 100 / ls_docs_classes-class_count.

        append  ls_docs_classes to lt_docs_classes.

      endloop. " loop at lt_valid_docs_param assigning field-symbol(<ls_valid_docs_param>).

      lv_score = 0.
      lv_final_score = 0.

      loop at lt_docs_classes assigning field-symbol(<ls_docs_classes>).

        loop at lt_valid_docs_status assigning <ls_valid_docs_status>
          where document_status = 'X'
          and document_type = <ls_docs_classes>-class_number.

          lv_score = lv_score + <ls_docs_classes>-class_elem_weight.

        endloop. "   loop at lt_valid_docs_status assigning <ls_valid_docs_status>

        ls_scores-class_number = <ls_docs_classes>-class_number.
        ls_scores-class_score = lv_score.
        ls_scores-class_weighted_score = ( lv_score * <ls_docs_classes>-class_weight ) / 100.

        lv_final_score = lv_final_score + ls_scores-class_weighted_score.

        append ls_scores to lt_scores.

        lv_score = 0.

      endloop.  " loop at lt_docs_classes ASSIGNING FIELD-SYMBOL(<ls_docs_classes>).

      " Putting a final score to a database

      if ( lv_final_score > '100.00' ).
        lv_final_score = '100.00'.
      endif.

      update crmd_customer_h set zzfld00000g = lv_final_score where guid = lv_guid.

      " ----------------  End of Score calculation  ------------------------

    endif. " if ( lv_new_flow_stage <> 'G' ).

    " Getting an email of a requestor

    select single persnumber addrnumber into (lv_persnumber, lv_addrnumber)
        from usr21 where bname eq lv_requestor_id.

    if sy-subrc eq 0.

      select single smtp_addr from adr6 into lv_requestor_email  where addrnumber = lv_addrnumber and persnumber = lv_persnumber.



    endif. "  if sy-subrc eq 0.

    " ----------------  Picking emails from org structure  ------------------------

    " Picking L1 approvers emails

    select single value from zvendunlockparam into lv_bp_num
      where param eq 'L1_BP_NUM'.

    call method zcl_zvendors_requests_dpc_ext=>get_emails_by_org_unit_bp
      exporting
        iv_bp     = lv_bp_num
      importing
        et_emails = lt_l1_emails.

    " Picking L2 approvers emails

    select single value from zvendunlockparam into lv_bp_num
      where param eq 'L2_BP_NUM'.

    call method zcl_zvendors_requests_dpc_ext=>get_emails_by_org_unit_bp
      exporting
        iv_bp     = lv_bp_num
      importing
        et_emails = lt_l2_emails.


    " -------------  End of Picking emails from org structure  ------------------

    " Scenarios based on selected action
    " Approval flow : Y -> U -> G


    case lv_action.

      when 'Approve'.

        " Finalizing score record to string (number + description)

        select single value from zvendunlockparam into lv_score_threshold_char
          where param eq 'SCORE_LOW'.

        lv_score_threshold_low = lv_score_threshold_char.

        select single value from zvendunlockparam into lv_score_threshold_char
            where param eq 'SCORE_HIGH'.

        lv_score_threshold_high = lv_score_threshold_char.

        if ( lv_final_score ge lv_score_threshold_high ).

          lv_score_name_param = 'SCORE_HIGH_NAME'.

        endif.

        if ( lv_final_score < lv_score_threshold_low ).

          lv_score_name_param = 'SCORE_LOW_NAME'.

        endif.

        if ( lv_final_score ge lv_score_threshold_low ) and ( lv_final_score < lv_score_threshold_high ).

          lv_score_name_param = 'SCORE_MIDDLE_NAME'.

        endif.

        select single value from zvendunlockparam into lv_score_text
          where param eq lv_score_name_param.

        lv_final_score_char = lv_final_score.
        condense lv_final_score_char.

        " Status change from initial to a second level of approval (from U to Y)

        if ( lv_new_flow_stage = 'Y' ).

          " ----------------  Level 1  approval ------------------------

          " Setting a binary mask of documents statuses and switching a flow stage

          select single * from crmd_customer_h into ls_customer_h where guid = lv_guid.          .

          ls_customer_h-zzfld00000e = lv_documents_mask_dec.
          ls_customer_h-zzfld000007 = lv_new_flow_stage.

          modify crmd_customer_h from ls_customer_h.

          " Setting of a  status of Level 1 Comitee Central approval

          if ( sy-subrc = 0 ).

            " Putting a status to In process

            ls_status-ref_guid = lv_guid.
            ls_status-ref_kind = 'A'.
            ls_status-status = 'E0002'.
            ls_status-user_stat_proc = 'ZMIN0001'.
            ls_status-activate = 'X'.

            append ls_status to lt_status.

*            api_object->set_status(
*              exporting
*                it_status             = lt_status    " Work Table for Status Info
*              changing
*                cv_log_handle         = ev_log_handle_charm   " Application Log: Log Handle
*              exceptions
*                document_locked       = 1
*                error_occurred        = 2
*                no_authority          = 3
*                no_change_allowed     = 4
*                others                = 5
*            ).

            if ( sy-subrc = 0 ).

              " Returning final score to frontend

              concatenate lv_object_id '|' lv_final_score_char into ls_header-value.
              concatenate ls_header-value '(' into ls_header-value separated by space.
              concatenate ls_header-value lv_score_text ')' into ls_header-value.

              ls_header-name = 'ZAPPROVAL_OK'.

              " L1 successfull approval: sending email to requestor

              "lv_receiver = 'andrew.kusnetsov@sap.com'.


              call method zcl_zapproval_helper=>vendor_request_notification
                exporting
                  iv_receiver          = lv_requestor_email
                  iv_subject_code      = 'L1_APP_MAIL_SUBJ_REQ'
                  iv_text_name         = 'ZVND_UNL_L1_APP_MAIL_REQ'
                  iv_full_name         = lv_full_name
                  iv_requestor         = lv_requestor
                  iv_vendor_code       = lv_vendor_code
                  iv_vendor_name       = lv_vendor_name
                  iv_company_code      = lv_company_code
                  iv_company_name      = lv_company_name
                  iv_system            = lv_system
                  iv_no_docs_option    = 'X'
                  iv_object_id         = lv_object_id
                  it_valid_docs_status = lt_valid_docs_status
                importing
                  ev_email_body        = lv_mail_msg.

              " Email text will become a comment text

              lv_add_text = lv_mail_msg.

              " Sending additional email to L2

              "lv_receiver = 'andrew.kusnetsov@sap.com'.

              select single value from zvendunlockparam into lv_receiver
                where param eq 'L2_EMAIL'.


              loop at lt_l2_emails assigning <ls_l2_emails>.

                call method zcl_zapproval_helper=>vendor_request_notification
                  exporting
                    iv_receiver          = <ls_l2_emails>-email
                    iv_subject_code      = 'L1_APP_MAIL_SUBJ_L2'
                    iv_text_name         = 'ZVND_UNL_L1_APP_MAIL_L2'
                    iv_full_name         = lv_full_name
                    iv_requestor         = lv_requestor
                    iv_vendor_code       = lv_vendor_code
                    iv_company_name      = lv_company_name
                    iv_vendor_name       = lv_vendor_name
                    iv_company_code      = lv_company_code
                    iv_system            = lv_system
                    iv_no_docs_option    = 'X'
                    iv_approval_link     = 'X'
                    iv_object_id         = lv_object_id
                    it_valid_docs_status = lt_valid_docs_status
                  importing
                    ev_email_body        = lv_mail_msg.

              endloop. " LOOP AT lt_l2_emails ASSIGNING <ls_l2_emails>.

              concatenate lv_mail_msg c_newline lv_add_text into lv_add_text separated by c_newline.

            else.

              " Setting header for failed status change

              ls_header-name = 'ZAPPROVAL_FAILED'.
              ls_header-value = lv_object_id.

            endif.  "  if ( sy-subrc = 0 ).


          else.

            " Setting header for failed flow stage change

            ls_header-name = 'ZAPPROVAL_FAILED'.
            ls_header-value = lv_object_id.

          endif. " if ( sy-subrc = 0 )

        endif. "  if ( lv_new_flow_stage = 'Y' )

        " ----------------  Level 2  approval ------------------------

        " Status change from a second level of approval to a final status (from Y to F)

        if ( lv_new_flow_stage = 'G' ).

          " Preparing parameter name to select destination

          concatenate lv_system '_RFC_DESTINATION' into lv_destination_param.

          select single value from zvendunlockparam into lv_destination
               where param = lv_destination_param.

          if lv_destination is initial.
            lv_destination = 'SM_SH1CLNT500_READ'.
          endif.


          if ( lv_company_code is not initial ) and ( lv_vendor_code is not initial ).

            " Preparing score for vendor update

            select single zzfld00000g from crmd_customer_h into lv_final_score where guid = lv_guid.

            lv_final_score_char = lv_final_score.

            " Calling vendor unlock routine on ERP
            " lv_return_code contains a final status for Level 2  approval

            call function 'ZVENDOR_UNLOCK' destination lv_destination
              exporting
                ip_vendor      = lv_vendor_code
                ip_bukrs       = lv_company_code
                ip_score       = lv_final_score_char
              importing
                ep_return_code = lv_return_code.


            " We continue processing in case vendor was unolocked (0) or master data lock will be processed later (3)

            if ( lv_return_code = 0 ) or ( lv_return_code = 3 ).


              if ( sy-subrc = 0 ).

                case lv_return_code.
                  when 0.
                    " Setting status to Confirmed
                    ls_status-status = 'E0008'.
                  when 3.
                    " Setting status to Solution Proposed
                    ls_status-status = 'E0005'.
                endcase.


                ls_status-ref_guid = lv_guid.
                ls_status-ref_kind = 'A'.
                ls_status-user_stat_proc = 'ZMIN0001'.
                ls_status-activate = 'X'.

                append ls_status to lt_status.



                if ( sy-subrc = 0 ) .

                  " Setting header for successfull unlock

                  ls_header-name = 'ZAPPROVAL_OK'.
                  ls_header-value = lv_vendor_code.

                  " ----------------  Attachments block  ------------------------


                  " Attachments relocation part
                  " Getting files migration parameter value

                  select single value from zvendunlockparam into lv_copy_attachments
                     where param = 'COPY_ATTACHMENTS'.

                  if ( lv_copy_attachments = 'X' ).

                    " Preparing a list of docid's for migration

                    api_object->get_attachment_list( importing et_attach_list = lt_attach_list ).

                    append initial line to l_tab_instid assigning field-symbol(<l_wa_instid>).
                    <l_wa_instid>-instid_a = lv_guid.

                    select *
                     from skwg_brel
                     into table l_tab_skwg
                     for all entries in l_tab_instid
                     where instid_a = l_tab_instid-instid_a
                     and instid_b like 'L/CRM_L%'.

                    sort l_tab_skwg by instid_a typeid_a catid_a.

                    delete adjacent duplicates from l_tab_skwg comparing instid_a typeid_a catid_a.

                    loop at l_tab_skwg into l_wa_skwg.
                      clear   : l_wa_busobject.

                      l_wa_busobject-instid = l_wa_skwg-instid_a.
                      l_wa_busobject-typeid = l_wa_skwg-typeid_a.
                      l_wa_busobject-catid  = l_wa_skwg-catid_a .

                    endloop. "    loop at l_tab_skwg into l_wa_skwg.

                    call method cl_crm_documents=>get_info
                      exporting
                        business_object       = l_wa_busobject
                      importing
                        phioloios             = lt_phioloios
                        ios_properties_result = lt_ios_prop_result.

                    loop at lt_phioloios into ls_phioloios.

                      ls_loio-objtype = ls_phioloios-objtypelo.
                      ls_loio-class = ls_phioloios-classlo.
                      ls_loio-objid = ls_phioloios-objidlo.
                      ls_phio-objtype = ls_phioloios-objtypeph.
                      ls_phio-class = ls_phioloios-classph.
                      ls_phio-objid = ls_phioloios-objidph.

                      " Binary will be contained in LINE of lt_bin_content with length of 1022

                      call method cl_crm_documents=>get_with_table
                        exporting
                          loio                = ls_loio
                          phio                = ls_phio
                          as_is_mode          = 'X'
                          raw_mode            = 'X'
                        importing
                          file_access_info    = lt_file_access_info
                          file_content_binary = lt_bin_content.

                      " Getting file details and preparing xstring variable

                      read table lt_file_access_info into ls_file_access_info index 1.

                      lv_input_length = ls_file_access_info-file_size.
                      lv_first_line = ls_file_access_info-first_line.
                      lv_last_line = ls_file_access_info-last_line.

                      call function 'SCMS_BINARY_TO_XSTRING'
                        exporting
                          input_length = lv_input_length
                          first_line   = lv_first_line
                          last_line    = lv_last_line
                        importing
                          buffer       = lv_data_xstr
                        tables
                          binary_tab   = lt_bin_content
                        exceptions
                          failed       = 1
                          others       = 2.


                      search ls_file_access_info-file_name for '...'.

                      if sy-fdpos > 0.

                        lv_extension = substring_after( val = ls_file_access_info-file_name sub = '.' ).

                        lv_filename = substring_before( val = ls_file_access_info-file_name sub = '.' ).

                      else.

                        lv_filename = ls_file_access_info-file_name.
                        lv_extension = 'DAT'.

                      endif. " if sy-fdpos


                      call function 'ZUPLOAD_VENDOR_DOCUMENTS' destination lv_destination
                        exporting
                          ip_vendor        = lv_vendor_code
                          ip_filename      = lv_filename
                          ip_fileextension = lv_extension
                          ip_filecontents  = lv_data_xstr
                        importing
                          ep_return_code   = lv_copy_result.

                    endloop. "  loop at lt_phioloios into ls_phioloios.


                    if ( lv_copy_result = 0 ).

                      select single value from zvendunlockparam into lv_delete_attachments
                         where param = 'DELETE_ATTACHMENTS'.

                      if ( lv_delete_attachments = 'X' ).


                        " Removing attachments from incident

                        api_object->get_attachment_list( importing et_attach_list = lt_attach_list ).

                        loop at lt_attach_list assigning <ls_attachment>.

                          ls_del_objects-objtype = <ls_attachment>-objtype.
                          ls_del_objects-class = <ls_attachment>-class.
                          ls_del_objects-objid = <ls_attachment>-objid.

                          append ls_del_objects to lt_del_objects.

                          api_object->delete_attachments(
                          exporting
                            is_business_object = ls_bus_objects
                            it_object_tab = lt_del_objects ).

                        endloop. " loop at lt_attach_list assigning field-symbol(<ls_attachment>).


                      endif. " if lv_delete_destination IS NOT INITIAL

                    endif. " if ( lv_copy_result = 0 )

                  endif. " if ( lv_copy_attachments = 'X' ).

                  concatenate lv_final_score_char '(' into lv_full_score separated by space.
                  concatenate lv_full_score lv_score_text ')' into lv_full_score.

                  "lv_receiver = 'andrew.kusnetsov@sap.com'.


                endif. "  if ( sy-subrc = 0 ).

              endif. "  if ( sy-subrc = 0 ).


              " Sending a final email to requestor and cleaning the queue if there's already a request existing

              if ( lv_return_code = 0 ).


                call method zcl_zapproval_helper=>vendor_request_notification
                  exporting
                    iv_receiver             = lv_requestor_email
                    iv_subject_code         = 'L2_APP_MAIL_SUBJ_REQ'
                    iv_text_name            = 'ZVND_UNL_L2_APP_MAIL_REQ'
                    iv_attachment_text_name = 'ZVND_UNL_L2_APP_ATT'
                    iv_no_docs_option       = 'X'
                    it_valid_docs_status    = lt_valid_docs_status
                    iv_requestor            = lv_requestor
                    iv_vendor_code          = lv_vendor_code
                    iv_vendor_name          = lv_vendor_name
                    iv_object_id            = lv_object_id
                    iv_full_name            = lv_full_name
                    iv_company_name         = lv_company_name
                    iv_company_code         = lv_company_code
                    iv_system               = lv_system
                    iv_score                = lv_full_score
                  importing
                    ev_email_body           = lv_mail_msg.

                " Email text will become a comment text

                lv_add_text = lv_mail_msg.

                select count(*) from zvendunlockqueue into lv_records_counter
                  where vendor_code = lv_vendor_code
                          and company_code = lv_company_code
                          and locked = 'X'.

                if ( lv_records_counter > 0 ).

                  update zvendunlockqueue
                    set
                         locked = ''
                         update_date = sy-datum
                         update_time = sy-uzeit
                    where
                          vendor_code = lv_vendor_code
                          and company_code = lv_company_code
                          and locked = 'X'.

                endif. " if ( lv_records_counter > 0 )

              endif.

              " Putting a request to the queue, as master data was locked
              if ( lv_return_code = 3 ).


                call method zcl_zapproval_helper=>vendor_request_notification
                  exporting
                    iv_receiver             = lv_requestor_email
                    iv_subject_code         = 'L2_APP_MAIL_SUBJ_REQ'
                    iv_text_name            = 'ZVND_UNL_L2_APP_MAIL_REQ'
                    iv_attachment_text_name = 'ZVND_UNL_L2_APP_ATT'
                    iv_no_docs_option       = 'X'
                    it_valid_docs_status    = lt_valid_docs_status
                    iv_requestor            = lv_requestor
                    iv_vendor_code          = lv_vendor_code
                    iv_vendor_name          = lv_vendor_name
                    iv_object_id            = lv_object_id
                    iv_full_name            = lv_full_name
                    iv_company_name         = lv_company_name
                    iv_company_code         = lv_company_code
                    iv_system               = lv_system
                    iv_score                = lv_full_score
                    iv_dont_send            = 'X'
                  importing
                    ev_email_body           = wa_zvendunlockqueue-email_text
                    ev_email_subject        = wa_zvendunlockqueue-email_subject
                    ev_attachment           = wa_zvendunlockqueue-attachment.

                " Email text will become a comment text

                lv_add_text = wa_zvendunlockqueue-email_text.

                wa_zvendunlockqueue-request_number = lv_object_id.
                wa_zvendunlockqueue-vendor_code = lv_vendor_code.
                wa_zvendunlockqueue-company_code = lv_company_code.
                wa_zvendunlockqueue-locked = 'X'.
                wa_zvendunlockqueue-enter_date = sy-datum.
                wa_zvendunlockqueue-enter_time = sy-uzeit.
                wa_zvendunlockqueue-email_receiver = lv_requestor_email.

                insert zvendunlockqueue from wa_zvendunlockqueue.

              endif.


            else. " if ( lv_return_code = 0 ) or ( lv_return_code = 3 ).

              " Setting header for failed unlock

              ls_header-name = 'ZAPPROVAL_FAILED'.
              ls_header-value = lv_return_code.


            endif. " if ( lv_return_code = 0 ).

          else.

            " Setting header for failed unlock if company and vendor details are missing

            ls_header-name = 'ZAPPROVAL_FAILED'.
            ls_header-value = '1'.

          endif. " if ( lv_company_code is not initial ) and ( lv_vendor_code is not initial ).

        endif.   "  if ( lv_new_flow_stage = 'G' )

        " when 'Approve'.

      when 'Reject'.

        select single zzfld000007 from crmd_customer_h into lv_current_flow_stage where guid = lv_guid.          .

        case lv_current_flow_stage.

          when 'U'.

            " ----------------  Level 1 rejection ------------------------

            "lv_receiver = 'andrew.kusnetsov@sap.com'.

            lv_comment_text = er_entity-comments.

            call method zcl_zapproval_helper=>vendor_request_notification
              exporting
                iv_receiver          = lv_requestor_email
                iv_subject_code      = 'L1_REJ_MAIL_SUBJ_REQ'
                iv_text_name         = 'ZVND_UNL_L1_REJ_MAIL_REQ'
                iv_full_name         = lv_full_name
                iv_requestor         = lv_requestor
                iv_vendor_code       = lv_vendor_code
                iv_company_name      = lv_company_name
                iv_vendor_name       = lv_vendor_name
                iv_company_code      = lv_company_code
                iv_system            = lv_system
                iv_no_docs_option    = 'X'
                iv_comments          = lv_comment_text
                iv_object_id         = lv_object_id
                it_valid_docs_status = lt_valid_docs_status
              importing
                ev_email_body        = lv_mail_msg.


            " Email text will become a comment text

            lv_add_text = lv_mail_msg.

          when 'Y'.

            " ----------------  Level 2 Committee Compliance rejection ------------------------


            "lv_receiver = 'andrew.kusnetsov@sap.com'.
            lv_comment_text = er_entity-comments.

            call method zcl_zapproval_helper=>vendor_request_notification
              exporting
                iv_receiver     = lv_requestor_email
                iv_subject_code = 'L2_REJ_MAIL_SUBJ_REQ'
                iv_text_name    = 'ZVND_UNL_L2_REJ_MAIL_REQ'
                iv_full_name    = lv_full_name
                iv_requestor    = lv_requestor
                iv_vendor_code  = lv_vendor_code
                iv_company_name = lv_company_name
                iv_vendor_name  = lv_vendor_name
                iv_company_code = lv_company_code
                iv_system       = lv_system
                iv_comments     = lv_comment_text
                iv_object_id    = lv_object_id
              importing
                ev_email_body   = lv_mail_msg.


            " Email text will become a comment text

            lv_add_text = lv_mail_msg.

            " Sending additional email to Comitee Central

            "lv_receiver = 'andrew.kusnetsov@sap.com'.

            select single value from zvendunlockparam into lv_receiver
              where param eq 'L1_EMAIL'.

            lv_comment_text = er_entity-comments.

            loop at lt_l1_emails assigning <ls_l1_emails>.

              call method zcl_zapproval_helper=>vendor_request_notification
                exporting
                  iv_receiver     = <ls_l1_emails>-email
                  iv_subject_code = 'L2_REJ_MAIL_SUBJ_L1'
                  iv_text_name    = 'ZVND_UNL_L2_REJ_MAIL_L1'
                  iv_full_name    = lv_full_name
                  iv_requestor    = lv_requestor
                  iv_vendor_code  = lv_vendor_code
                  iv_company_name = lv_company_name
                  iv_vendor_name  = lv_vendor_name
                  iv_company_code = lv_company_code
                  iv_system       = lv_system
                  iv_comments     = lv_comment_text
                  iv_object_id    = lv_object_id
                importing
                  ev_email_body   = lv_mail_msg.

            endloop. "

            concatenate lv_mail_msg c_newline lv_add_text into lv_add_text separated by c_newline.

*
        endcase.

        if ( sy-subrc = 0 ).

          ls_header-name = 'ZREJECTION_OK'.
          ls_header-value = lv_object_id.

        else.

          ls_header-name = 'ZREJECTION_FAILED'.
          ls_header-value = lv_object_id.

        endif.   "    if ( sy-subrc = 0 )

    endcase.  " case lv_action.

    " ------------------------------  Adding comment text ----------------------------

    if lv_add_text is not initial.

      " Basic text details preparation

      ls_text-ref_guid = lv_guid.
      ls_text-tdid = 'SU01'.
      ls_text-tdspras = 'E'.
      ls_text-tdstyle = 'SYSTEM'.
      ls_text-mode = 'I'.

      " Removing special characters

      replace all occurrences of '<p>' in lv_add_text with ' '.
      replace all occurrences of '</p>' in lv_add_text with ' '.
      replace all occurrences of '&nbsp;' in lv_add_text with ' '.
      replace all occurrences of '<strong>' in lv_add_text with ' '.
      replace all occurrences of '</strong>' in lv_add_text with ' '.

      " Algorithm for comments text wrapping

      split lv_add_text at c_newline into table lt_prep_text_lines.

      loop at lt_prep_text_lines assigning field-symbol(<ls_prep_text_lines>).

        refresh lt_add_text_wrapped.

        lv_add_text_line = <ls_prep_text_lines>-tdline.

        if ( lv_add_text_line <> '' ).

          condense lv_add_text_line.

          call function 'SWA_STRING_SPLIT'
            exporting
              input_string         = lv_add_text_line
              max_component_length = 80
            tables
              string_components    = lt_add_text_wrapped.

          loop at lt_add_text_wrapped assigning field-symbol(<ls_add_text_wrapped>).

            ls_text_line-tdline = <ls_add_text_wrapped>-str.
            append ls_text_line to lt_text_lines.

          endloop. "   loop at lt_add_text_wrapped assigning field-symbol(<ls_add_text_wrapped>).

        else.
          ls_text_line-tdline = lv_add_text_line.
          append ls_text_line to lt_text_lines.
        endif. "  if ( lv_add_text_line <> '' ).

      endloop. "  loop at lt_prep_text_lines assigning field-symbol(<ls_prep_text_lines>).

      ls_text-lines = lt_text_lines.
      append ls_text to lt_text.

      api_object->set_texts(
         exporting
           it_text           =  lt_text  " Text Extension: Workarea (One Order)
         exceptions
           error_occurred    = 1
           document_locked   = 2
           no_change_allowed = 3
           no_authority      = 4
           others            = 5
       ).

    endif. " IF lv_add_text IS NOT INITIAL.

    " -------------  Finalizing status for rejection ---------------------------------

    if ( lv_action = 'Reject' ).

      " Setting status as Withdrawn for all rejections

      ls_status-ref_guid = lv_guid.
      ls_status-ref_kind = 'A'.
      ls_status-status = 'E0010'.
      ls_status-user_stat_proc = 'ZMIN0001'.
      ls_status-activate = 'X'.

      append ls_status to lt_status.

*      api_object->set_status(
*        exporting
*          it_status             = lt_status    " Work Table for Status Info
*        changing
*          cv_log_handle         = ev_log_handle_charm   " Application Log: Log Handle
*        exceptions
*          document_locked       = 1
*          error_occurred        = 2
*          no_authority          = 3
*          no_change_allowed     = 4
*          others                = 5
*      ).

      " update CRM_JEST table for rejection
      select * from crm_jest where objnr = @lv_guid into table @data(lt_crm_jest).

      loop at lt_crm_jest into data(ls_crm_jest).
        ls_crm_jest-inact = 'X'.
        modify crm_jest from ls_crm_jest.
      endloop.

      " user status
      ls_crm_jest-chgnr = '001'.
      ls_crm_jest-inact = ''.
      ls_crm_jest-objnr = lv_guid.
      ls_crm_jest-stat = 'E0010'.
      insert into crm_jest values ls_crm_jest.

      " system status
      ls_crm_jest-chgnr = '001'.
      ls_crm_jest-inact = ''.
      ls_crm_jest-objnr = lv_guid.
      ls_crm_jest-stat = 'I1005'.
      insert into crm_jest values ls_crm_jest.


    endif. " if ( lv_action = 'Reject' ).


    " ------------------------------  Setting status and saving order document  ----------------------------


      if lt_status is not initial.

        api_object->set_status(
      exporting
        it_status             = lt_status    " Work Table for Status Info
      changing
        cv_log_handle         = ev_log_handle_charm   " Application Log: Log Handle
      exceptions
        document_locked       = 1
        error_occurred        = 2
        no_authority          = 3
        no_change_allowed     = 4
        others                = 5
    ).

      endif. " if lt_status is not initial.

      " Saving a Change Document

      call method api_object->save( changing cv_log_handle = ev_log_handle_charm ).



    " -------------  Finalizing flow for final statuses---------------------------- -----------------

    if ( lv_new_flow_stage = 'G' ) and ( ( lv_return_code = '0' ) or ( lv_return_code = '3' ) ).

      update crmd_customer_h set zzfld000007 = lv_new_flow_stage where guid = lv_guid.

    endif. "  if ( lv_new_flow_stage = 'G' )


    " -------------  Setting final HTTP headers for successfull POST execution-----------------


    set_header( is_header = ls_header ).



  endmethod.