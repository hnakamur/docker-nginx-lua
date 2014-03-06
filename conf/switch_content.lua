local session_id = ngx.var.cookie_inter_app_session
if (session_id ~= nil) then
    ngx.exec("@private")
else
    ngx.exec("@public")
end
