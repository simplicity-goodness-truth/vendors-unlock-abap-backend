  class-methods GET_MONO_PDF
    importing
      !IV_FORMNAME type CHAR0032
      !IV_STATEMENT type STRING
      !IT_DOCUMENTS type ZTABLE_OF_CHAR256 optional
      !IV_SCORE type CHAR256 optional
    exporting
      !ET_RETURN type BAPIRETTAB
      !EV_BINARY_FILE type XSTRING
      !EV_PDFSIZE type I .

  method GET_MONO_PDF.

  DATA: i_fname TYPE  tdsfname.

  DATA: fm_name            TYPE rs38l_fnam,
        ls_output_options      TYPE ssfcompop,
        control_parameters TYPE ssfctrlop,
     "   ls_saida           TYPE zetfi_report_irf_compensar,
        job_output_info    TYPE ssfcrescl,
        lv_devtype             TYPE rspoptype,
        lv_language            TYPE tdspras.


  i_fname = IV_FORMNAME.

* Busca nome do smartforms
  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      formname           = i_fname
    IMPORTING
      fm_name            = fm_name
    EXCEPTIONS
      no_form            = 1
      no_function_module = 2
      OTHERS             = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  lv_language = sy-langu.

  TRANSLATE lv_language TO UPPER CASE.
  control_parameters-langu = lv_language.
* set control parameters to get the output text format (OTF) from Smart Forms
  control_parameters-no_dialog = 'X'.
  control_parameters-getotf   = 'X'.
  control_parameters-preview = space. "No preview

* get device type from language
  CALL FUNCTION 'SSF_GET_DEVICE_TYPE'
    EXPORTING
      i_language            = lv_language
*     i_application          = 'SAPDEFAULT'
    IMPORTING
      e_devtype             = lv_devtype
    EXCEPTIONS
      no_language           = 1
      language_not_installed = 2
      no_devtype_found      = 3
      system_error          = 4
      OTHERS                = 5.
* set device type in output options
  ls_output_options-tdprinter = lv_devtype.
* Set relevant output options
  ls_output_options-tdnewid = 'X'. "Print parameters,
  ls_output_options-tddelete = space. "Print parameters

  CALL FUNCTION fm_name
    EXPORTING
      control_parameters = control_parameters
      output_options     = ls_output_options
      iv_statement       = iv_statement
      iv_score           = iv_score
    IMPORTING
      job_output_info    = job_output_info
    TABLES
      it_documents       = it_documents
    EXCEPTIONS
      formatting_error   = 1
      internal_error     = 2
      send_error         = 3
      user_canceled      = 4
      OTHERS             = 5.

  CHECK sy-subrc = 0.
  DATA:
    pdf_table      TYPE TABLE OF tline.

  CALL FUNCTION 'CONVERT_OTF'
    EXPORTING
      format                = 'PDF'
    IMPORTING
      bin_filesize          = EV_PDFSIZE
      bin_file              = EV_BINARY_FILE
    TABLES
      otf                   = job_output_info-otfdata
      lines                 = pdf_table
    EXCEPTIONS
      err_max_linewidth     = 1
      err_format            = 2
      err_conv_not_possible = 3
      OTHERS                = 4.

  endmethod.