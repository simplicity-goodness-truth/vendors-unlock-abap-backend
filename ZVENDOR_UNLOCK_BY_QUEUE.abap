*&---------------------------------------------------------------------*
*& Report  ZVENDOR_UNLOCK_BY_QUEUE
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
report zvendor_unlock_by_queue.

data lt_zvendunlockqueue type table of zvendunlockqueue.

data wa_zvendunlockqueue type zvendunlockqueue.
"data lv_records_counter type integer.
data lv_final_score type p decimals 2.
data lv_final_score_char(11) type c.
data lv_return_code type sy-subrc.
data lv_destination type char256.

data: email          type ref to zcl_aba_mail_notification,
      lv_email       type so_recname,
      lv_send_result type c.

data et_solix type solix_tab.
data ls_formfield type ihttpnvp.
data lv_subject_draft type char1024.
data lv_subject type string.
data lv_receiver type string.

data api_object type ref to cl_ags_crm_1o_api.


data: lt_status type crmt_status_comt,
      ls_status type crmt_status_com.

data ev_log_handle_charm type balloghndl.
data lv_guid type crmt_object_guid.

select request_number vendor_code company_code email_text email_receiver email_subject attachment
  from zvendunlockqueue
  into corresponding fields of table lt_zvendunlockqueue
  where locked = 'X'.

select single value from zvendunlockparam into lv_destination
     where param = 'ERP_RFC_DESTINATION'.

if lv_destination is initial.
  lv_destination = 'SM_SH1CLNT500_READ'.
endif.

loop at lt_zvendunlockqueue assigning field-symbol(<ls_zvendunlockqueue>).

  " Preparing score for vendor update

  select single zzfld00000g
      from ( crmd_customer_h as o
              inner join crmd_orderadm_h as c on o~guid = c~guid  )
     into lv_final_score
     where c~object_id = <ls_zvendunlockqueue>-request_number.

  lv_final_score_char = lv_final_score.

  call function 'ZVENDOR_UNLOCK' destination lv_destination
    exporting
      ip_vendor      = <ls_zvendunlockqueue>-vendor_code
      ip_bukrs       = <ls_zvendunlockqueue>-company_code
      ip_score       = lv_final_score_char
    importing
      ep_return_code = lv_return_code.

  if ( lv_return_code = 0 ).

    update zvendunlockqueue
      set
      locked = ''
      update_date = sy-datum
      update_time = sy-uzeit
      where
       vendor_code = <ls_zvendunlockqueue>-vendor_code
       and company_code = <ls_zvendunlockqueue>-company_code
       and locked = 'X'.

    " Updating status

    select single guid from crmd_orderadm_h into lv_guid  where object_id = <ls_zvendunlockqueue>-request_number.

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

    " Setting status as Confirmed

    ls_status-ref_guid = lv_guid.
    ls_status-ref_kind = 'A'.
    ls_status-status = 'E0008'.
    ls_status-user_stat_proc = 'ZMIN0001'.
    ls_status-activate = 'X'.

    append ls_status to lt_status.

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

    call method api_object->save( changing cv_log_handle = ev_log_handle_charm ).


    " Sending an email


    if ( <ls_zvendunlockqueue>-email_subject is not initial ) and
      ( <ls_zvendunlockqueue>-email_receiver is not initial ) and
      ( <ls_zvendunlockqueue>-email_text is not initial ).


      if email is not initial.
        free email.
      endif.

      lv_subject_draft = <ls_zvendunlockqueue>-email_subject.

      translate lv_subject_draft to lower case.
      translate lv_subject_draft+0(1) to upper case.

      lv_subject = lv_subject_draft.

      create object email
        exporting
          i_general_mail   = abap_true
          i_subject        = lv_subject
          i_header_subject = lv_subject.

      email->set_header_logo( ).

      lv_receiver = <ls_zvendunlockqueue>-email_receiver.
      translate lv_receiver to lower case.

      move lv_receiver to lv_email.

      call method email->add_force_receiver exporting email = lv_email.


      email->set_sender( i_sender = 'no-reply@sonangol.co.ao' ).


      ls_formfield = value ihttpnvp(  name = 'message'
                                     value = <ls_zvendunlockqueue>-email_text  ).

      email->add_formfields( value ihttpnvp(  name = 'message'
                                     value = <ls_zvendunlockqueue>-email_text  ) ).


      if  <ls_zvendunlockqueue>-attachment is not initial.


        cl_bcs_convert=>xstring_to_solix(
           exporting
                iv_xstring = <ls_zvendunlockqueue>-attachment
           receiving
                et_solix = et_solix ).

        email->add_attachment(
          attachment_type  = 'pdf'
          attachment_subject = 'Desbloqueio aprovado'
          att_content_hex = et_solix
          ).

      endif. "  if  <ls_zvendunlockqueue>-attachment IS NOT INITIAL.

      email->set_it_email_message( i_is_bsp = abap_true ).

      email->send(
          exporting
            i_with_error_screen    = 'X'    " Flag geral
            i_set_request_atts     = 'E'    " Flag geral
          receiving
            r_result               = lv_send_result
          exceptions
            failed_to_send         = 1
            others                 = 2
        ).

    endif. " if ( <ls_zvendunlockqueue>-email_subject IS NOT INITIAL )

  else.
    update zvendunlockqueue
  set
  update_date = sy-datum
  update_time = sy-uzeit
  where
   vendor_code = <ls_zvendunlockqueue>-vendor_code
   and company_code = <ls_zvendunlockqueue>-company_code
   and locked = 'X'.

  endif.

endloop. "loop at lt_zvendunlockqueue ASSIGNING FIELD-SYMBOL(<ls_zvendunlockqueue>).
