function contained(comma_list_str, str)
  for v in string.gmatch(comma_list_str, "[^,]+") do
    if v == str then
      return true
    end
  end
  return false
end

local granted = false
local deleted = false
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
    local value = client:hget('file', ngx.var.uri)
    if value ~= ngx.null then
      local task_id, op = string.match(value, '^([^:]*):(.*)$')
      ngx.header["X-Debug-task-id"] = { 'task_id=' .. task_id }
      ngx.header["X-Debug-op"] = { 'op=' .. op }
      if contained(tasks, task_id) then
        granted = true
        if op == 'delete' then
          deleted = true
        end
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

ngx.header["X-Debug-granted"] = { string.format('granted=%s', granted) }
if granted then
  if deleted then
    ngx.exec("@deleted")
  else
    ngx.exec("@private")
  end
else
  ngx.exec("@public")
end
