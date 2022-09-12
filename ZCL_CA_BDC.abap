class ZCL_CA_BDC definition
  public
  final
  create public .

public section.

  data LAST_RESULT type SY-MSGTY read-only .

  type-pools ABAP .
  methods IS_AT_LEAST_ONE_FIELD_FILLED
    returning
      value(RP_AT_LEAST_ONE_FIELD_FILLED) type ABAP_BOOL .
  methods CONSTRUCTOR
    importing
      !TCODE type SY-TCODE .
  methods ADD_SCREEN
    importing
      !PROGRAM type BDCDATA-PROGRAM
      !SCREEN type BDCDATA-DYNPRO
      !COMMAND type BDCDATA-FNAM optional .
  methods ADD_FIELD
    importing
      !FIELD type BDCDATA-FNAM
      !VALUE type ANY .
  methods RESET .
  methods RUN
    returning
      value(RESULT) type BAPIRET2_TAB .
protected section.
private section.

  data BDC_DATA type BDCDATA_TAB .
  data BDC_TCODE type SY-TCODE .
  data BDC_RESULT type TAB_BDCMSGCOLL .
  data BDC_PARAMS type CTU_PARAMS .
ENDCLASS.



CLASS ZCL_CA_BDC IMPLEMENTATION.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_CA_BDC->ADD_FIELD
* +-------------------------------------------------------------------------------------------------+
* | [--->] FIELD                          TYPE        BDCDATA-FNAM
* | [--->] VALUE                          TYPE        ANY
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD add_field.

    DATA: ls_bdc_data LIKE LINE OF bdc_data.
    DATA: lv_datatype TYPE char1.

    DESCRIBE FIELD value TYPE lv_datatype.
    CLEAR ls_bdc_data.

    ls_bdc_data-fnam = field.
    CASE lv_datatype.
      WHEN 'D'.
        WRITE value TO ls_bdc_data-fval  ##WRITE_MOVE.
      WHEN 'P'.
        WRITE value TO ls_bdc_data-fval NO-GROUPING  ##WRITE_MOVE.

        CONDENSE ls_bdc_data-fval.
      WHEN OTHERS.
        ls_bdc_data-fval = value .
    ENDCASE.

    APPEND ls_bdc_data TO bdc_data.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_CA_BDC->ADD_SCREEN
* +-------------------------------------------------------------------------------------------------+
* | [--->] PROGRAM                        TYPE        BDCDATA-PROGRAM
* | [--->] SCREEN                         TYPE        BDCDATA-DYNPRO
* | [--->] COMMAND                        TYPE        BDCDATA-FNAM(optional)
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD add_screen.
    DATA: ls_bdc_data LIKE LINE OF bdc_data.

    CLEAR ls_bdc_data.
    ls_bdc_data-program  = program.
    ls_bdc_data-dynpro   = screen.
    ls_bdc_data-dynbegin = 'X'.
    APPEND ls_bdc_data TO bdc_data.


    IF command IS SUPPLIED.
      add_field( field = 'BDC_OKCODE'
                 value = command ).
    ENDIF.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_CA_BDC->CONSTRUCTOR
* +-------------------------------------------------------------------------------------------------+
* | [--->] TCODE                          TYPE        SY-TCODE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD constructor.
    bdc_tcode = tcode.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_CA_BDC->IS_AT_LEAST_ONE_FIELD_FILLED
* +-------------------------------------------------------------------------------------------------+
* | [<-()] RP_AT_LEAST_ONE_FIELD_FILLED   TYPE        ABAP_BOOL
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method IS_AT_LEAST_ONE_FIELD_FILLED.

    rp_at_least_one_field_filled = abap_false.

    if bdc_data is not initial.

      rp_at_least_one_field_filled = abap_true.

    endif.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_CA_BDC->RESET
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD reset.
    CLEAR bdc_data[].
    CLEAR bdc_result[].

    CLEAR last_result.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_CA_BDC->RUN
* +-------------------------------------------------------------------------------------------------+
* | [<-()] RESULT                         TYPE        BAPIRET2_TAB
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD run.

    CLEAR bdc_result[].

    bdc_params-racommit = 'X'.
    bdc_params-defsize = 'X'.
    bdc_params-dismode = 'N'.

    CALL TRANSACTION bdc_tcode
      WITH AUTHORITY-CHECK
      USING bdc_data
      MESSAGES INTO bdc_result
      OPTIONS FROM bdc_params.

    DATA: ls_bdc_result LIKE LINE OF bdc_result.
    DATA: ls_bapi_return LIKE LINE OF result.

    CLEAR last_result.

    LOOP AT bdc_result INTO ls_bdc_result.
      IF ls_bdc_result-msgid = '00' AND ls_bdc_result-msgnr = '344' AND ls_bdc_result-msgtyp = 'S'.
        ls_bdc_result-msgtyp = 'E'.
      ENDIF.

      IF ls_bdc_result-msgtyp = 'E' OR ls_bdc_result-msgtyp = 'A'.
        last_result = 'E'.
        EXIT.
      ENDIF.

      IF ls_bdc_result-msgtyp = 'W' AND NOT last_result = 'E'.
        last_result = 'W'.
        CONTINUE.
      ENDIF.

      IF ( ls_bdc_result-msgtyp = 'I' OR ls_bdc_result-msgtyp = 'S' ) AND NOT ( last_result = 'E' OR last_result = 'W' ).
        last_result = 'I'.
      ENDIF.
    ENDLOOP.

    IF result IS SUPPLIED.

      LOOP AT bdc_result INTO ls_bdc_result.
        ls_bapi_return-type = ls_bdc_result-msgtyp.
        ls_bapi_return-id = ls_bdc_result-msgid.
        ls_bapi_return-number = ls_bdc_result-msgnr.
        ls_bapi_return-message_v1 = ls_bdc_result-msgv1.
        ls_bapi_return-message_v2 = ls_bdc_result-msgv2.
        ls_bapi_return-message_v3 = ls_bdc_result-msgv3.
        ls_bapi_return-message_v4 = ls_bdc_result-msgv4.

        DATA: lv_message TYPE sy-lisel.

        CALL FUNCTION 'RPY_MESSAGE_COMPOSE'
          EXPORTING
            message_id        = ls_bapi_return-id
            message_number    = ls_bapi_return-number
            message_var1      = ls_bapi_return-message_v1
            message_var2      = ls_bapi_return-message_v2
            message_var3      = ls_bapi_return-message_v3
            message_var4      = ls_bapi_return-message_v4
          IMPORTING
            message_text      = lv_message
          EXCEPTIONS
            message_not_found = 1
            OTHERS            = 2.
        IF sy-subrc <> 0.
          ls_bapi_return-message = ''.
        ELSE.
          ls_bapi_return-message = lv_message.
        ENDIF.

        APPEND ls_bapi_return TO result.
      ENDLOOP.

    ENDIF.
  ENDMETHOD.
ENDCLASS.