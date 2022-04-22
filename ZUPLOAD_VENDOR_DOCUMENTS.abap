FUNCTION zupload_vendor_documents.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IP_VENDOR) TYPE  LIFNR
*"     VALUE(IP_FILECONTENTS) TYPE  XSTRING
*"     VALUE(IP_FILENAME) TYPE  STRING
*"     VALUE(IP_FILEEXTENSION) TYPE  SOODK-OBJTP
*"  EXPORTING
*"     VALUE(EP_RETURN_CODE) TYPE  SY-SUBRC
*"----------------------------------------------------------------------

  DATA lv_xstring TYPE xstring.
  DATA g_folderid TYPE soodk.

  CALL FUNCTION 'SO_FOLDER_ROOT_ID_GET'
    EXPORTING
      region    = 'B'
    IMPORTING
      folder_id = g_folderid.

  DATA g_docdata TYPE sodocchgi1.

  DATA: git_objhdr     TYPE TABLE OF solisti1,
        wa_git_objhdr  TYPE solisti1,
        git_hexcont    TYPE TABLE OF solix,
        lt_contents    TYPE solix_tab,
        ls_git_hexcont TYPE solix,
        g_docinfo      TYPE sofolenti1.

  DATA lo_converter TYPE REF TO cl_bcs_convert.

  CREATE OBJECT lo_converter.
  DATA: lv_row_len  TYPE i,
        lv_filesize TYPE i.

  DATA: g_bizojb     TYPE borident,
        g_attachment TYPE borident.

  CALL METHOD cl_bcs_convert=>xstring_to_solix
    EXPORTING
      iv_xstring = ip_filecontents
    RECEIVING
      et_solix   = lt_contents.

  DESCRIBE TABLE lt_contents.

  lv_row_len  = sy-tfill.

  READ TABLE git_hexcont INTO ls_git_hexcont INDEX lv_row_len.
  lv_filesize = ( 255 * ( lv_row_len - 1 ) ) + xstrlen( ls_git_hexcont-line  ).

  g_docdata-obj_name  = ip_filename.
  g_docdata-obj_descr = ip_filename.
  g_docdata-obj_langu = sy-langu.
  g_docdata-doc_size = lv_filesize.

  CONCATENATE '&SO_FILENAME=' ip_filename INTO wa_git_objhdr-line.
  APPEND wa_git_objhdr TO git_objhdr.
  CLEAR: wa_git_objhdr.
  wa_git_objhdr-line = '&SO_FORMAT=TXT'.
  APPEND wa_git_objhdr TO git_objhdr.

  TRANSLATE ip_fileextension TO UPPER CASE.

  CALL FUNCTION 'SO_DOCUMENT_INSERT_API1'
    EXPORTING
      folder_id                  = g_folderid
      document_data              = g_docdata
      document_type              = ip_fileextension
    IMPORTING
      document_info              = g_docinfo
    TABLES
      object_header              = git_objhdr
      contents_hex               = lt_contents
    EXCEPTIONS
      folder_not_exist           = 1
      document_type_not_exist    = 2
      operation_no_authorization = 3
      parameter_error            = 4
      x_error                    = 5
      enqueue_error              = 6
      OTHERS                     = 7.

  IF sy-subrc = 0.

    g_bizojb-objtype = 'LFA1'.
    g_bizojb-objkey  = ip_vendor.

    g_attachment-objkey  = g_docinfo-doc_id.
    g_attachment-objtype = 'MESSAGE'.

    CALL FUNCTION 'BINARY_RELATION_CREATE'
      EXPORTING
        obj_rolea    = g_bizojb
        obj_roleb    = g_attachment
        relationtype = 'ATTA'.

    IF sy-subrc = 0.

      ep_return_code =  0.
      COMMIT WORK.

    ELSE.
      ep_return_code =  sy-subrc.
    ENDIF. " IF sy-subrc = 0.

  ELSE.

    ep_return_code =  sy-subrc.

  ENDIF.  " IF sy-subrc = 0.


ENDFUNCTION.