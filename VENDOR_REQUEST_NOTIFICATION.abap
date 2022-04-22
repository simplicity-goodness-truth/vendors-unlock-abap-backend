  class-methods VENDOR_REQUEST_NOTIFICATION
    importing
      !IV_RECEIVER type STRING
      !IV_ATTACHMENT_TEXT_NAME type CHAR0032 optional
      !IV_TEXT_NAME type STRING optional
      !IV_FULL_NAME type AD_NAMTEXT optional
      !IV_REQUESTOR type CHAR100 optional
      !IV_VENDOR_CODE type CHAR10 optional
      !IV_COMPANY_NAME type CHAR25 optional
      !IV_COMPANY_CODE type CHAR4 optional
      !IV_SYSTEM type CHAR3 optional
      !IV_NO_DOCS_OPTION type CHAR1 optional
      !IV_APPROVAL_LINK type CHAR1 optional
      !IV_COMMENTS type STRING optional
      !IV_OBJECT_ID type CRMT_OBJECT_ID_DB
      !IV_SUBJECT_CODE type CHAR256
      !IT_VALID_DOCS_STATUS type TT_VALID_DOCS_STATUS optional
      !IV_VENDOR_NAME type CHAR35 optional
      !IV_SCORE type CHAR256 optional
      !IV_DONT_SEND type CHAR1 optional
    exporting
      !EV_EMAIL_BODY type STRING
      !EV_EMAIL_SUBJECT type STRING
      !EV_ATTACHMENT type XSTRING.

  method vendor_request_notification.

    data ls_formfield type ihttpnvp.

    data lv_receiver type c length 1215.

    data: email          type ref to zcl_aba_mail_notification,
          lv_email       type so_recname,
          lv_send_result type c.

    data lt_text_name type  thead-tdname.

    data lt_valid_docs_status type tt_valid_docs_status.

    field-symbols <ls_valid_docs_status> like line of it_valid_docs_status.

    data lv_subject type string.
    data lv_subject_draft type char256.
    data lv_date_char type char10.
    data:
      lv_mail_msg        type string,
      lv_mail_msg_tmp    type string,
      t_line             type table of tline,
      l_line             type char255,
      lv_attachment_text type string.

    data ls_valid_docs_status type ty_valid_docs_status_tt.

    data lv_text_token type char256.
    data c_newline value cl_abap_char_utilities=>newline.

    data lv_validated_docs_count type integer.
    data lv_text_name type string.
    data lv_xstring type xstring.
    data et_solix type solix_tab.
    data lt_return         type bapirettab.

    data lv_attachment_text_name type char0032.

    data lt_documents_for_pdf type ztable_of_char256.
    data ls_documents_for_pdf like line of lt_documents_for_pdf.


    " Links related data

    data lv_level2_link type char256.
    data lv_level2_link_name type char256.


    " ----------------  Input parameters block ------------------------


    " Filling subject

    select single value from zvendunlockparam into lv_subject_draft where param = iv_subject_code.

    translate lv_subject_draft to lower case.
    translate lv_subject_draft+0(1) to upper case.

    replace all occurrences of '$request_number$' in lv_subject_draft with iv_object_id.

    lv_subject = lv_subject_draft.


    " Taking text from SO10 and replacing tokens

    lv_text_name = iv_text_name.

    if ( iv_no_docs_option = 'X' ).

      " Checking amount of validated documents

      lv_validated_docs_count = 0.

      loop at it_valid_docs_status transporting no fields where document_status = 'X'.
        lv_validated_docs_count = lv_validated_docs_count + 1.
      endloop.

      if ( lv_validated_docs_count = 0 ).
        concatenate iv_text_name '_NODOCS' into lv_text_name.
      endif.

    endif. " IF ( iv_no_docs_option = 'X' ).

    lt_text_name = lv_text_name.


    clear:   t_line.
    refresh: t_line.

    call function 'READ_TEXT'
      exporting
        client                  = sy-mandt
        id                      = 'ST'
        language                = 'P'
        name                    = lt_text_name
        object                  = 'TEXT'
      tables
        lines                   = t_line
      exceptions
        id                      = 1
        language                = 2
        name                    = 3
        not_found               = 4
        object                  = 5
        reference_check         = 6
        wrong_access_to_archive = 7
        others                  = 8.

    concatenate sy-datum+6(2) sy-datum+4(2) sy-datum(4) into lv_date_char  separated by '.'.

    loop at t_line into l_line.

      concatenate '<strong>' iv_requestor '</strong>' into lv_text_token.
      condense lv_text_token.
      replace '&1' with lv_text_token into l_line.

      concatenate '<strong>' iv_full_name '</strong>' into lv_text_token.
      condense lv_text_token.
      replace '&2' with lv_text_token into l_line.

      concatenate '<strong>' lv_date_char '</strong>' into lv_text_token.
      condense lv_text_token.
      replace '&3' with lv_text_token into l_line.

      concatenate '<strong>' iv_vendor_code '-' iv_vendor_name '</strong>' into lv_text_token.
      condense lv_text_token.
      replace '&4' with lv_text_token into l_line.

      concatenate '<strong>' iv_company_code '-' iv_company_name '</strong>' into lv_text_token.
      condense lv_text_token.
      replace '&5' with lv_text_token into l_line.

      concatenate '<strong>' iv_system '</strong>' into lv_text_token.
      condense lv_text_token.
      replace '&6' with lv_text_token into l_line.

      concatenate lv_mail_msg l_line+2 into lv_mail_msg separated by space.

    endloop. "       loop at t_line into l_line.

    lt_valid_docs_status[] = it_valid_docs_status[].

    if ( it_valid_docs_status is not initial ).

      loop at lt_valid_docs_status assigning <ls_valid_docs_status> where document_status = 'X'.

        translate <ls_valid_docs_status>-document_text to lower case.
        translate <ls_valid_docs_status>-document_text+0(1) to upper case.


        concatenate lv_mail_msg '<p>&nbsp;</p>' into lv_mail_msg.
        concatenate lv_mail_msg c_newline '<p><strong>' <ls_valid_docs_status>-document_text '</strong></p>' into lv_mail_msg.

        " If attachment should be printed, then we remember a list of documents
        if ( iv_attachment_text_name is not initial ).

          " concatenate lv_attach_docs '<p>&nbsp;</p>' into lv_attach_docs.
          "   concatenate lv_attach_docs c_newline  <ls_valid_docs_status>-document_text  into lv_attach_docs.

          ls_documents_for_pdf = <ls_valid_docs_status>-document_text.
          append ls_documents_for_pdf to lt_documents_for_pdf.

        endif.

      endloop. "  loop at lt_valid_docs_status assigning field-symbol(<ls_valid_docs_status>) where document_status = 'X'.


    endif.

    " Adding comments

    if ( iv_comments <> '' ).

      concatenate lv_mail_msg '<p>&nbsp;</p>' into lv_mail_msg.
      concatenate lv_mail_msg c_newline '<p>Comentários:</p>' into lv_mail_msg.
      concatenate lv_mail_msg '<p>&nbsp;</p>' into lv_mail_msg.
      concatenate lv_mail_msg c_newline '<p>' iv_comments '</p>' into lv_mail_msg.

    endif. " if ( lv_comment_text <> '' ).

    " Adding a link to email. Link should not appear in comments!


    if ( iv_approval_link = 'X' ).


      select single value from zvendunlockparam into lv_level2_link where param = 'L1_APP_MAIL_LINK_L2'.
      select single value from zvendunlockparam into lv_level2_link_name where param = 'L1_APP_MAIL_LINKN_L2'.

      if ( lv_level2_link is not initial ) and ( lv_level2_link_name is not initial ).

        lv_mail_msg_tmp = lv_mail_msg.

        translate lv_level2_link to lower case.

        translate lv_level2_link_name to lower case.
        translate lv_level2_link_name+0(1) to upper case.

        concatenate lv_mail_msg '<p>&nbsp;</p>' into lv_mail_msg.
        concatenate lv_mail_msg c_newline '<p><a href=''' lv_level2_link '''>' lv_level2_link_name '</a></p>' into lv_mail_msg.

      endif.  "  IF ( lv_level2_link IS not initial ) and ( lv_level2_link_name IS not initial ).

    endif. " if ( iv_approval_link = 'X' ).


    " ----------------  Attachments block -------------------


    if ( iv_attachment_text_name is not initial ).

      lv_attachment_text_name = iv_attachment_text_name.
      condense lv_attachment_text_name.

      if ( iv_no_docs_option = 'X' ).

        " Checking amount of validated documents

        lv_validated_docs_count = 0.

        describe table lt_documents_for_pdf lines lv_validated_docs_count.


        if ( lv_validated_docs_count = 0 ).


          concatenate lv_attachment_text_name '_NODOCS' into lv_attachment_text_name.

          ls_documents_for_pdf = 'Esta aprovação foi feita sem qualquer validação da documentação.'.
          append ls_documents_for_pdf to lt_documents_for_pdf.


        endif. " if ( lv_validated_docs_count = 0 ).

      endif. " IF ( iv_no_docs_option = 'X' ).

      lt_text_name = lv_attachment_text_name.

      clear:   t_line.
      refresh: t_line.

      call function 'READ_TEXT'
        exporting
          client                  = sy-mandt
          id                      = 'ST'
          language                = 'P'
          name                    = lt_text_name
          object                  = 'TEXT'
        tables
          lines                   = t_line
        exceptions
          id                      = 1
          language                = 2
          name                    = 3
          not_found               = 4
          object                  = 5
          reference_check         = 6
          wrong_access_to_archive = 7
          others                  = 8.


      loop at t_line into l_line.

        replace '&1' with iv_requestor into l_line.

        replace '&2' with iv_full_name into l_line.

        replace '&3' with lv_date_char into l_line.

        concatenate  iv_vendor_code '-' iv_vendor_name  into lv_text_token.

        replace '&4' with lv_text_token into l_line.

        concatenate iv_company_code '-' iv_company_name into lv_text_token.

        replace '&5' with lv_text_token into l_line.

        replace '&6' with iv_system into l_line.

        concatenate lv_attachment_text l_line+2 into lv_attachment_text separated by space.

      endloop. "       loop at t_line into l_line.

      " Generating pdf with smartform ZVENDOR_UNLOCK_STATEMENT

      zcl_zvendors_requests_dpc_ext=>get_mono_pdf(
         exporting
           iv_statement = lv_attachment_text
           iv_formname  = 'ZVENDOR_UNLOCK_STATEMENT'
           it_documents = lt_documents_for_pdf
           iv_score     = iv_score
        importing
           et_return         = lt_return
           ev_binary_file    = lv_xstring

           ).

    endif. " if ( iv_attachment_text_name is not initial ).

    " ----------------  Sending block ------------------------

    if email is not initial.
      free email.
    endif.

    create object email
      exporting
        i_general_mail   = abap_true
        i_subject        = lv_subject
        i_header_subject = lv_subject.

    email->set_header_logo( ).


    move iv_receiver to lv_email.

    call method email->add_force_receiver exporting email = lv_email.


    email->set_sender( i_sender = 'no-reply@sonangol.co.ao' ).

    ls_formfield = value ihttpnvp(  name = 'message'
                                   value = lv_mail_msg  ).

    email->add_formfields( value ihttpnvp(  name = 'message'
                                   value = lv_mail_msg  ) ).



    if ( iv_attachment_text_name is not initial ).

      " convering xstring to solix

      cl_bcs_convert=>xstring_to_solix(
          exporting
               iv_xstring = lv_xstring
          receiving
               et_solix = et_solix ).

      email->add_attachment(
        attachment_type  = 'pdf'
        attachment_subject = 'Desbloqueio aprovado'
        att_content_hex = et_solix
        ).

    endif.


    if  ( iv_dont_send <> 'X' ).

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

    endif. "if  ( iv_dont_send <> 'X' ).


    if ( iv_approval_link = 'X' ).
      lv_mail_msg = lv_mail_msg_tmp.
    endif.  " if ( iv_approval_link = 'X' ).

    ev_email_body = lv_mail_msg.

    ev_email_subject = lv_subject.
    ev_attachment = lv_xstring.

  endmethod.