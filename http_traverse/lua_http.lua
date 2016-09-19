#!/usr/bin/lua

--- basic setup
target = "http://127.0.0.1/"
port = "80"

num_threads = 2
num_reqs = 10 ---requests per thread

--- configuration
i = 0
wget_params = " --background --output-file=wget_log.txt"

function pick_random_page()
  p = 1
  lines = {}
  file = io.open("paths.txt","r");
  if not file then
    os.exit()
  end

  for line in file:lines() do
    lines[p] = line
    print(line)
    p = p + 1
  end

  p = math.random(1,#lines)
  return lines[p]
end


function do_requests(num_reqs)
  j = 0
  while(j < num_reqs) do
    path = pick_random_page()
    cmd = "wget " .. target .. ":" .. port .. path .. wget_params .. " &"
    os.execute(cmd)
    os.execute("sleep 1")
    j = j + 1
  end
end

--- if spawned child
if (arg[1] == "1") then
  do_requests(num_reqs)
  os.exit()
else
  spawn_cmd = "lua lua_http.lua 1"

  while(i<num_threads) do
    --print(spawn_cmd)
    os.execute(spawn_cmd)
    i = i + 1
  end
end

os.exit()
