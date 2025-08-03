create or replace package body pkg_generate_report as

  v_app_id                 number;
  v_page_id                number;
procedure sql2xml(in_app_id  number,
                     in_page_id number,
                     out_clob   out clob) as
  
    l_ctx dbms_xmlgen.ctxhandle;
    lv_collection_name constant apex_collections.collection_name%type default 'REPORT_HEADER';
    rec_report_name  APEX_APPLICATION_GLOBAL.VC_ARR2;
    rec_report_value APEX_APPLICATION_GLOBAL.VC_ARR2;
    rec_names        apex_application_global.vc_arr2;
    rec_values       apex_application_global.vc_arr2;
    cur              number;
    cur1             sys_refcursor;
    lv_bind_val      varchar2(4000);
    v_sql_query      varchar2(32767);
    lv_binds         DBMS_SQL.VARCHAR2_TABLE;
    ret              number;
    v_labels_query   clob;
    v_items_query    varchar2(32767);
    pivot_columns    varchar2(4000);
  begin
  
    v_page_id := in_page_id;
    v_app_id  := in_app_id;
  
    select region_id
      into l_region_id
      from apex_application_page_regions
     where page_id = in_page_id
       and application_id = in_app_id
       and source_type = 'Interactive Report';
    
    select sql_query
      into v_sql_query
      from apex_application_page_ir
     where application_id = v_app_id
       and page_id = v_page_id;
  
    lv_binds := wwv_flow_utilities.get_binds(v_sql_query);
    for i in 1 .. lv_binds.COUNT loop
    
      lv_bind_val := v(LTRIM(UPPER(lv_binds(i)), ':'));
      rec_report_name(i) := replace(lv_binds(i), ':');
      rec_report_value(i) := lv_bind_val;
    
    end loop;
  
    cur := dbms_sql.open_cursor;
   
    
    v_sql_query := 'select cursor (' || v_sql_query ||
                   ') as rowset1
                    from dual';

    dbms_sql.parse(cur, v_sql_query, dbms_sql.native);
  
    for z in 1 .. rec_report_name.count loop
      dbms_sql.bind_variable(cur, rec_report_name(z), rec_report_value(z));
    end loop;
  
    ret := dbms_sql.execute(cur);
  
    cur1 := dbms_sql.to_refcursor(cur);
  
    l_ctx := dbms_xmlgen.newcontext(cur1);
  
    dbms_xmlgen.setrowsettag(l_ctx, 'DATA_DS');
    dbms_xmlgen.setrowtag(l_ctx, 'ROW');
    out_clob := dbms_xmlgen.getXml(l_ctx);
    dbms_xmlgen.closeContext(l_ctx);
  
  end sql2xml;
end pkg_generate_report;
