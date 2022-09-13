function zvendor_unlock.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IP_VENDOR) TYPE  LIFNR
*"     VALUE(IP_BUKRS) TYPE  BUKRS
*"     VALUE(IP_SCORE) TYPE  KRAUS_CM OPTIONAL
*"  EXPORTING
*"     VALUE(EP_RETURN_CODE) TYPE  SY-SUBRC
*"----------------------------------------------------------------------


  " Return codes
  " 0 - all OK
  " 1 - technical error
  " 2 - there is no vendor lock situation
  " 3 - vendor master data is under Exclusive lock

  data: lv_single_payment_block type sperb_x,
        lv_all_payment_blocks   type sperb_x,
        lv_all_purchase_blocks  type sperb_x,
        lv_function_block       type qsperrfkt,
        lv_confs                type confs_x,
        lv_failed_operation     type char1,
        lt_enqueue              type table of seqg3,
        lv_enq_args             like seqg3-garg,
        lv_master_data_locked   type char1,
        lt_lfb1                 type table of lfb1,
        ls_lfb1                 like line of lt_lfb1,
        lo_zcl_ca_bdc           type ref to zcl_ca_bdc,
        lt_bdc_exec_result      type standard table of bapiret2,
        ls_bdc_exec_result      like line of lt_bdc_exec_result.

  lv_failed_operation = ''.
  lv_master_data_locked = ''.

  " Check if vendor is unlocked but not confirmed yet

  select single * from lfb1 into @ls_lfb1 where bukrs = @ip_bukrs and lifnr = @ip_vendor and confs = 1.

  if sy-subrc = 0.
    data(lv_confirm_block) = abap_true.
  endif.


  " Check for block for one company

  select single sperr from lfb1 into lv_single_payment_block  where lifnr = ip_vendor and bukrs = ip_bukrs.

  " Check for block for all companies and for all purchasing organizations

  select single sperr sperm sperq from lfa1 into (lv_all_payment_blocks, lv_all_purchase_blocks, lv_function_block ) where lifnr = ip_vendor.

  " Checking if vendor master data is locked

  concatenate sy-mandt ip_vendor into lv_enq_args.

  condense lv_enq_args.

  call function 'ENQUEUE_READ'
    exporting
      gclient               = sy-mandt
      gname                 = 'LFA1'
      garg                  = lv_enq_args
      guname                = '*'
    tables
      enq                   = lt_enqueue
    exceptions
      communication_failure = 1
      system_failure        = 2
      others                = 3.

  if sy-subrc <> 0.

    lv_failed_operation = 'X'.

  endif.

  loop at lt_enqueue assigning field-symbol(<ls_enqueue>).

    if <ls_enqueue>-gmode = 'E'.

      lv_master_data_locked = 'X'.

    endif.

  endloop. "  LOOP AT lt_enqueue ASSIGNING FIELD-SYMBOL(<ls_enqueue>).

  " Initializing BDC processing class, screen and fields

  lo_zcl_ca_bdc = new zcl_ca_bdc( tcode = 'XK05' ).

  lo_zcl_ca_bdc->add_screen( program = 'SAPMF02K' screen =  '0500' command = '/00' ).
  lo_zcl_ca_bdc->add_field( field = 'RF02K-LIFNR' value =  ip_vendor  ).
  lo_zcl_ca_bdc->add_field( field = 'RF02K-BUKRS' value =  ip_bukrs  ).
  lo_zcl_ca_bdc->add_screen( program = 'SAPMF02K' screen =  '0510' command = '=UPDA' ).

  " Dropping lock for one company

  if ( lv_single_payment_block = 'X' ).

    lo_zcl_ca_bdc->add_field( field = 'LFB1-SPERR' value =  ' '  ).

  endif. "IF ( lv_single_payment_block = 'X' ).

  " Dropping lock for all companies and filling score

  if ( lv_master_data_locked <> 'X' ).

    if ( lv_all_payment_blocks = 'X' ).

      lo_zcl_ca_bdc->add_field( field = 'LFA1-SPERR' value =  ' '  ).

    endif. " IF ( lv_all_payment_blocks = 'X' ).

    " Dropping lock for all purchasing organizations

    if ( lv_all_purchase_blocks = 'X' ).

      lo_zcl_ca_bdc->add_field( field = 'LFA1-SPERM' value =  ' '  ).

    endif. " IF ( lv_all_payment_blocks = 'X' ).

    " Dropping function lock

    if ( lv_function_block <> '' ).

      lo_zcl_ca_bdc->add_field( field = 'LFA1-SPERQ' value =  ' '  ).

    endif. " IF ( ip_score is not INITIAL ).

    " Setting score value

    if ( ip_score is not initial ).

      update lfa1 set kraus  = ip_score where lifnr = ip_vendor.

      if ( sy-subrc <> 0 ).
        lv_failed_operation = 'X'.
      endif. " IF ( sy-subrc <> 0 ).

    endif. " IF ( ip_score is not INITIAL ).

  endif. " IF ( lv_master_data_locked <> 'X' ).

  " Executing BDC sequence

  if ( lo_zcl_ca_bdc->is_at_least_one_field_filled( ) eq abap_true ) and ( lv_master_data_locked <> 'X' ).

    lt_bdc_exec_result = lo_zcl_ca_bdc->run( ).

    ls_bdc_exec_result = lt_bdc_exec_result[ 1 ].

    if ( ls_bdc_exec_result-type ne 'S' ).

      lv_failed_operation = 'X'.

    endif.

  endif. " if ( lo_zcl_ca_bdc->is_at_least_one_field_filled( ) eq abap_true )


  if ( lv_single_payment_block = 'X' ) or ( lv_all_payment_blocks = 'X' ) or ( lv_all_purchase_blocks = 'X' ) or ( lv_function_block <> '' ) or ( lv_confirm_block = abap_true ).

    ep_return_code = 0.

    " Checking whether vendor requires confirmation and confirming, if necessary

    select single confs from lfa1 into lv_confs where lifnr = ip_vendor.

    if ( lv_confs = '1' ) and ( lv_master_data_locked <> 'X' ).

      update lfa1 set confs = '' where lifnr = ip_vendor.

      if ( sy-subrc <> 0 ).
        lv_failed_operation = 'X'.
      endif. " IF ( sy-subrc <> 0 ).

    endif.  "    IF ( lv_confs = '1' ).

    lv_confs = ''.

    select single confs from lfb1 into lv_confs where lifnr = ip_vendor and bukrs = ip_bukrs.

    if ( lv_confs = '1' ) and ( lv_master_data_locked <> 'X' ).

      update lfb1 set confs = '' where lifnr = ip_vendor and bukrs = ip_bukrs.

      if ( sy-subrc <> 0 ).
        lv_failed_operation = 'X'.
      endif. " IF ( sy-subrc <> 0 ).

    endif.  "    IF ( lv_confs = '1' ).

    if ( ( lv_all_payment_blocks = 'X' ) or ( lv_all_purchase_blocks = 'X' ) or ( lv_function_block <> '' ) or ( lv_confirm_block = abap_true ) ) and ( lv_master_data_locked = 'X' ).

      ep_return_code = 3.

    endif.


  else. " IF ( lv_single_payment_block = 'X' ) OR ( lv_all_payment_blocks = 'X' ) OR ( ( lv_all_payment_blocks = 'X' )

    ep_return_code = 2.

  endif. "  IF ( lv_single_payment_block = 'X' ) OR ( lv_all_payment_blocks = 'X' ) OR ( ( lv_all_payment_blocks = 'X' )

  if ( lv_failed_operation = 'X' ).

    ep_return_code = 1.

  endif. "     IF ( lv_failed_operation = 'X' ).


endfunction.