local granted = false
local session_id = ngx.var.cookie_inter_app_session
if (session_id ~= nil) then
    local redis = require "resty.redis"
    local client = redis:new()
    client:connect(os.getenv("REDIS_PORT_6379_TCP_ADDR"), tonumber(os.getenv("REDIS_PORT_6379_TCP_PORT")))
    local tasks, err = client:get(session_id)
    if not tasks then
        ngx.say("failed to get from redis: session_id=", session_id, ", err=", err)
        ngx.exit(500)
        return
    end

    if tasks ~= ngx.null then
        local task_from_uri = string.match(ngx.var.uri, '^/([^/]*)')
        ngx.header["X-Debug-tasks"] = { 'tasks=' .. tasks }
        for task in string.gmatch(tasks, "[^,]+") do
            if task_from_uri == task then
                granted = true
                ngx.header["X-Debug-granted"] = { string.format('granted=%s', granted) }
                break
            end
        end
    end

    -- put it into the connection pool of size 100,
    -- with 10 seconds max idle time
    local ok, err = client:set_keepalive(10000, 100)
    if not ok then
        ngx.say("failed to set keepalive: ", err)
        ngx.exit(500)
        return
    end
end

if granted then
    ngx.exec("@private")
else
    ngx.exec("@public")
end
