FUNCTION zvendors_data_provider.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IP_MODE) TYPE  CHAR1
*"     VALUE(IP_VENDOR) TYPE  LIFNR OPTIONAL
*"     VALUE(IP_BUKRS) TYPE  BUKRS OPTIONAL
*"  EXPORTING
*"     VALUE(EP_RETURN_CODE) TYPE  SY-SUBRC
*"  TABLES
*"      ET_ZVENDOR_BASIC_DETAILS STRUCTURE  ZVENDOR_BASIC_DETAILS
*"       OPTIONAL
*"      ET_ZVENDOR_EXTENDED_DETAILS STRUCTURE  ZVENDOR_EXTENDED_DETAILS
*"       OPTIONAL
*"      ET_ZCOMPANIES_BASIC_DETAILS STRUCTURE  ZCOMPANIES_BASIC_DETAILS
*"----------------------------------------------------------------------

  DATA lt_lfa1 TYPE STANDARD TABLE OF lfa1.
  DATA lt_setleaf TYPE STANDARD TABLE OF setleaf.
  DATA ls_setleaf LIKE LINE OF lt_setleaf.

  DATA lv_zahls TYPE dzahls.
  DATA lv_tax_country TYPE qland.
 " DATA lv_bukrs TYPE bukrs.



  DATA lv_payment_block TYPE sperb_x.



  " Mode 0: list of all avaiable vendors
  " Mode 1: particular vendor details
  " Mode 2: check of particular vendor
  " Mode 3: list of all availavle companies
  " Mode 4: particular company details
  " Mode 5: active companies in set ZS_SD_VENDOR_FIORI_WLIST

  CASE ip_mode.

    WHEN '0'.
      SELECT lifnr name1
        FROM lfa1
        INTO CORRESPONDING FIELDS OF TABLE et_zvendor_basic_details.

      IF ( sy-subrc = 0 ).
        ep_return_code = 0.
      ELSE.
        ep_return_code = 1.
      ENDIF.   "  IF ( sy-subrc = 0 )

    WHEN '1'.
      IF ( ip_vendor IS NOT INITIAL ).

*    Vendor code  lifnr
*    Vendor name  name1
*    Address land1 regio ort01 stras PSTLZ
*    Blocked for posting  SPERR
*    Payment details  LFB1-ZTERM + LFB1-ZWELS
*    NIF code	STCD1
*    Withholding tax type	T059P-witht
*    Reconciliation account	LFB1-AKONT
*    Administrative data  LFBK-BANKS + LFBK-BANKL + LFBK-BANKN + LFBK-KOINH
*    Vendor email	ADR6-SMTP_ADDR
*    Contact persons  KNVK-NAME1
*    Telephone  TELF1

        SELECT * FROM lfa1 INTO TABLE lt_lfa1
              UP TO 1 ROWS
          WHERE lifnr = ip_vendor.

        LOOP AT lt_lfa1 ASSIGNING FIELD-SYMBOL(<ls_lfa1>).

          et_zvendor_extended_details-lifnr = <ls_lfa1>-lifnr.
          et_zvendor_extended_details-name1 = <ls_lfa1>-name1.
          et_zvendor_extended_details-land1 = <ls_lfa1>-land1.
          et_zvendor_extended_details-regio = <ls_lfa1>-regio.
          et_zvendor_extended_details-ort01 = <ls_lfa1>-ort01.
          et_zvendor_extended_details-stras = <ls_lfa1>-stras.
          et_zvendor_extended_details-pstlz = <ls_lfa1>-pstlz.
          et_zvendor_extended_details-telf1 = <ls_lfa1>-telf1.
          et_zvendor_extended_details-stcd1 = <ls_lfa1>-stcd1.

          " Vendor email address

          SELECT SINGLE smtp_addr INTO et_zvendor_extended_details-smtp_addr
            FROM adr6 WHERE  addrnumber = <ls_lfa1>-adrnr.

          " Reconciliation account and payment details

          SELECT SINGLE akont zwels zterm zahls qland sperr  INTO (et_zvendor_extended_details-akont, et_zvendor_extended_details-zwels, et_zvendor_extended_details-zterm,
            lv_zahls, lv_tax_country, et_zvendor_extended_details-sperr)
            FROM lfb1 WHERE lifnr = <ls_lfa1>-lifnr and bukrs = ip_bukrs.

          " Bank details

          SELECT SINGLE banks bankl bankn koinh INTO (et_zvendor_extended_details-banks, et_zvendor_extended_details-bankl, et_zvendor_extended_details-bankn, et_zvendor_extended_details-koinh)
            FROM lfbk WHERE lifnr = <ls_lfa1>-lifnr.

          " Payment block text
          SELECT SINGLE textl INTO et_zvendor_extended_details-textl
             FROM t008t WHERE zahls = lv_zahls AND spras = sy-langu.

          " Withhold tax type

          SELECT SINGLE witht INTO et_zvendor_extended_details-witht
              FROM t059p WHERE land1 = lv_tax_country.

          " Contact person

          SELECT SINGLE name1 INTO et_zvendor_extended_details-cnt_name
              FROM knvk WHERE lifnr = <ls_lfa1>-lifnr.

          " Company code and name

         IF ( ip_bukrs IS NOT INITIAL ).

          SELECT SINGLE butxt INTO et_zvendor_extended_details-butxt
              FROM t001 WHERE bukrs = ip_bukrs.

         ENDIF.

          et_zvendor_extended_details-bukrs = ip_bukrs.

          APPEND et_zvendor_extended_details.

        ENDLOOP.

        IF ( lt_lfa1 IS NOT INITIAL ).
          ep_return_code = 0.
        ELSE.
          ep_return_code = 1.
        ENDIF.   "  IF ( sy-subrc = 0 )

      ELSE.
        ep_return_code = 1.
      ENDIF. "IF ( ip_vendor IS NOT INITIAL )

    WHEN '2'.

      IF ( ip_vendor IS NOT INITIAL ) AND ( ip_bukrs IS NOT INITIAL ).

        " Blocking flag and company code

        SELECT SINGLE sperr FROM lfb1 INTO lv_payment_block WHERE lifnr like ip_vendor AND bukrs = ip_bukrs.

        IF ( lv_payment_block = 'X' ).

          ep_return_code = 0.

        ELSE.
          ep_return_code = 1.
        ENDIF.

      ELSE.
        ep_return_code = 1.
      ENDIF.

    WHEN '3'.
      SELECT bukrs butxt
        FROM t001
        INTO CORRESPONDING FIELDS OF TABLE et_zcompanies_basic_details.

      IF ( sy-subrc = 0 ).
        ep_return_code = 0.
      ELSE.
        ep_return_code = 1.
      ENDIF.   "  IF ( sy-subrc = 0 )

     WHEN '4'.
      SELECT bukrs butxt
        FROM t001
        INTO CORRESPONDING FIELDS OF TABLE et_zcompanies_basic_details
        WHERE bukrs = ip_bukrs.

      IF ( sy-subrc = 0 ).
        ep_return_code = 0.
      ELSE.
        ep_return_code = 1.
      ENDIF.   "  IF ( sy-subrc = 0 )


    WHEN '5'.
      SELECT bukrs butxt
        FROM t001
        INTO CORRESPONDING FIELDS OF TABLE et_zcompanies_basic_details.

      LOOP AT et_zcompanies_basic_details ASSIGNING FIELD-SYMBOL(<ls_zcompanies_details>).
        SELECT SINGLE * FROM setleaf INTO ls_setleaf WHERE setname = 'ZS_SD_VENDOR_FIORI_WLIST' AND valfrom = <ls_zcompanies_details>-bukrs.
        IF sy-subrc <> 0.
          DELETE et_zcompanies_basic_details WHERE bukrs = <ls_zcompanies_details>-bukrs.
        ENDIF.
      ENDLOOP.

      IF ( sy-subrc = 0 ).
        ep_return_code = 0.
      ELSE.
        ep_return_code = 1.
      ENDIF.   "  IF ( sy-subrc = 0 )

  ENDCASE. " CASE ip_mode.

ENDFUNCTION.