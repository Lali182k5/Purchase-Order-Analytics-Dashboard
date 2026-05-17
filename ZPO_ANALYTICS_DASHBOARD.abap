REPORT zpo_analytics_dashboard.

*---------------------------------------------------------------------*
* Selection Screen
*---------------------------------------------------------------------*
DATA: gv_ebeln TYPE ekko-ebeln,
      gv_lifnr TYPE ekko-lifnr,
      gv_bedat TYPE ekko-bedat.

PARAMETERS: p_bukrs TYPE ekko-bukrs OBLIGATORY.

SELECT-OPTIONS:
  s_ebeln FOR gv_ebeln,
  s_lifnr FOR gv_lifnr,
  s_bedat FOR gv_bedat.

*---------------------------------------------------------------------*
* Type Declaration
*---------------------------------------------------------------------*
TYPES: BEGIN OF ty_po,
         ebeln TYPE ekko-ebeln,
         bukrs TYPE ekko-bukrs,
         lifnr TYPE ekko-lifnr,
         bedat TYPE ekko-bedat,
         matnr TYPE ekpo-matnr,
         menge TYPE ekpo-menge,
         netwr TYPE ekpo-netwr,
       END OF ty_po.

DATA: gt_po TYPE STANDARD TABLE OF ty_po,
      gs_po TYPE ty_po.

DATA: gr_alv TYPE REF TO cl_salv_table,
      gr_events TYPE REF TO cl_salv_events_table.

*---------------------------------------------------------------------*
* Event Handler Class
*---------------------------------------------------------------------*
CLASS lcl_event_handler DEFINITION.
  PUBLIC SECTION.
    METHODS: on_double_click
      FOR EVENT double_click OF cl_salv_events_table
      IMPORTING row column.
ENDCLASS.

CLASS lcl_event_handler IMPLEMENTATION.
  METHOD on_double_click.
    READ TABLE gt_po INTO gs_po INDEX row.
    IF sy-subrc = 0.
      SET PARAMETER ID 'BES' FIELD gs_po-ebeln.
      CALL TRANSACTION 'ME23N' AND SKIP FIRST SCREEN.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

DATA: go_handler TYPE REF TO lcl_event_handler.

*---------------------------------------------------------------------*
* START-OF-SELECTION
*---------------------------------------------------------------------*
START-OF-SELECTION.

  SELECT a~ebeln
         a~bukrs
         a~lifnr
         a~bedat
         b~matnr
         b~menge
         b~netwr
    INTO TABLE gt_po
    FROM ekko AS a
    INNER JOIN ekpo AS b
      ON a~ebeln = b~ebeln
    WHERE a~bukrs = p_bukrs
      AND a~ebeln IN s_ebeln
      AND a~lifnr IN s_lifnr
      AND a~bedat IN s_bedat.

  IF gt_po IS INITIAL.
    MESSAGE 'No records found' TYPE 'I'.
    EXIT.
  ENDIF.

*---------------------------------------------------------------------*
* ALV Display
*---------------------------------------------------------------------*
  TRY.

      cl_salv_table=>factory(
        IMPORTING r_salv_table = gr_alv
        CHANGING  t_table      = gt_po ).

      gr_events = gr_alv->get_event( ).

      CREATE OBJECT go_handler.
      SET HANDLER go_handler->on_double_click FOR gr_events.

      gr_alv->display( ).

    CATCH cx_salv_msg.
      MESSAGE 'ALV Error Occurred' TYPE 'E'.
  ENDTRY.
