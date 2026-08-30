prompt === Generate and persist a bounded AI summary in a valid APEX session ===
declare
    l_summary clob;
begin
    l_summary := hr_ai_pkg.generate_request_summary(
        p_request_id => :REQUEST_ID);
    dbms_output.put_line(dbms_lob.substr(l_summary, 4000, 1));
    commit;
end;
/
