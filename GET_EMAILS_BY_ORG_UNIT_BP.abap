class ZCL_ZVENDORS_REQUESTS_DPC_EXT definition
  public
  inheriting from ZCL_ZVENDORS_REQUESTS_DPC
  create public .

public section.

  types:
    begin of ty_doclist_tt,
        line(32) type c,
      end of ty_doclist_tt .
  types:
    tt_doclist type table of ty_doclist_tt .
  types:
    begin of ty_emails_tt,
             email type string,
           end of ty_emails_tt .
  types:
    tt_emails type table of ty_emails_tt .

  class-methods GET_EMAILS_BY_ORG_UNIT_BP
    importing
      !IV_BP type REALO
    exporting
      !ET_EMAILS type TT_EMAILS .
  class-methods CS_DOCUMENTS_COPY_TO_OTHER_CS
    importing
      !IP_REPDST type SDOKSTCA-STOR_REP
      !IP_REPSRC type SDOKSTCA-STOR_REP
      !IT_DOCUMENTS type TT_DOCLIST
    exporting
      !EP_RETURN_CODE type SY-SUBRC .
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

  method get_emails_by_org_unit_bp.

    types: begin of ty_bp_tt,
             bp type bu_partner,
           end of ty_bp_tt.

    data lt_bp type standard table of ty_bp_tt.

    data ls_emails type ty_emails_tt.

    field-symbols <ls_bp> like line of lt_bp.

    data lv_employee_uname type uname.
    data: lv_addrnumber type ad_addrnum,
          lv_persnumber type ad_persnum.


    " Receiving BP for employees of L1 ogr unit

    select partner2 into table lt_bp from but050 where partner1 = iv_bp and reltyp = 'BUR010'.

    loop at lt_bp assigning <ls_bp>.

      call function 'CRM_ERMS_FIND_USER_FOR_BP'
        exporting
          ev_bupa_no = <ls_bp>-bp
        importing
          ev_user_id = lv_employee_uname.

      select single persnumber addrnumber into (lv_persnumber, lv_addrnumber)
          from usr21 where bname eq lv_employee_uname.

      if sy-subrc eq 0.

        select single smtp_addr from adr6 into ls_emails-email  where addrnumber = lv_addrnumber and persnumber = lv_persnumber.

        append ls_emails to et_emails .

      endif. "  if sy-subrc eq 0.

    endloop. " LOOP AT lt_bp ASSIGNING <ls_bp>


  endmethod.