#!/usr/bin/lua -f
--
-- 'parse_lmbench.lua' Copyright (C) 2016 Unicamp
--
-- This software was developed by João Moreira <joao.moreira@lsc.ic.unicamp.br>
-- at Universidade Estadual de Campinas - Unicamp, Campinas, SP, Brazil, in
-- February 2016
--
-- This program is free software: you can redistribute it and/or modify it under
-- the terms of the GNU General Public License as published by the Free Software
-- Foundation, either version 3 of the License, or (at your option) any later
-- version.
--
-- This program is distributed in the hope that it will be useful, but WITHOUT
-- ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
-- FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
-- details.
--
-- You should have received a copy of the GNU General Public License along with
-- this program. If not, see <http://www.gnu.org/licenses/>.
--
--
-- 'parse_lmbench.lua' (lmbench results parser)
--
-- this program parses results of runs of the benchmark lmbench-3.0 and outputs
-- it in the csv format. inputs must be the result of make LIST=<OS> feature,
-- present in lmbench-3.0. This program is particularly useful while comparing
-- results of different runs, as it will accept different input files and output
-- with correct columns for future analysis.
--
-- This first version only parses results for the OS related tests.
--
-- Usage: lua parse_lmbench.lua <result> <description> <result> <description>...
--
-- <result>:
-- - output of make LIST=<OS> from lmbench benchmark
-- <description>:
-- - description for the numbers in the file pointed by the previous argument
--

-- change this to specify how many reruns you did for each lmbench configuration
num_tests = 5

function format(value)
  if(string.sub(value, string.len(value), string.len(value)) == "K") then
    value = string.sub(value, 1, string.len(value)-1)
    value = value * 1000
  elseif(string.sub(value, string.len(value), string.len(value)) == ".") then
    value = string.sub(value, 1, string.len(value)-1)
  end
  return value
end

function get_proc(file, desc)
  list = io.open(file, "r");
  list:seek("set")
  values = {}
  i = 1
  while i <= num_tests do
    values[i] = {}
    i = i + 1
  end
  c = -1
  z = 1
  for l in list:lines() do
    a = string.match(l, "^(Processor), Processes");
    if(a) then
      c = 0
    elseif(c >= 4 + num_tests) then
      c = -1
    elseif(c >= 4) then
      values[c - 3]["host"] = string.gsub(string.sub(l,1,8)," ","")
      values[c - 3]["OS"] = string.gsub(string.sub(l,10,23)," ","")
      values[c - 3]["Mhz"] = format(string.sub(l,25,28))
      values[c - 3]["nullcall"] = format(string.sub(l,30,33))
      values[c - 3]["nullio"] = format(string.sub(l,35,38))
      values[c - 3]["stat"] = format(string.sub(l,40,43))
      values[c - 3]["openclos"] = format(string.sub(l,45,48))
      values[c - 3]["slcttcp"] = format(string.sub(l,50,53))
      values[c - 3]["siginst"] = format(string.sub(l,55,58))
      values[c - 3]["sighndl"] = format(string.sub(l,60,63))
      values[c - 3]["forkproc"] = format(string.sub(l,65,68))
      values[c - 3]["execproc"] = format(string.sub(l,70,73))
      values[c - 3]["shproc"] = format(string.sub(l,75,78))
      c = c + 1
    elseif(c >= 0) then
      c = c + 1
    end
  end
  i = 1
  if file == arg[1] then
    print("\n\n\n\n\n\nProcessor Processes - times in microseconds - smaller is better")
    print("description,host,OS,Mhz,null call,null I/O,stat,open clos,slct TCP,sig inst,sig hndl,fork proc,exec proc,sh proc")
  end
  while i <= num_tests  do
    print(desc .. "," .. values[i]["host"] .. "," .. values[i]["OS"] .. "," .. values[i]["Mhz"] .. "," .. values[i]["nullcall"] .. "," .. values[i]["nullio"] .. "," .. values[i]["stat"] .. "," .. values[i]["openclos"] .. "," .. values[i]["slcttcp"] .. "," .. values[i]["siginst"] .. "," .. values[i]["sighndl"] .. "," .. values[i]["forkproc"] .. "," .. values[i]["execproc"] .. "," .. values[i]["shproc"])
    i = i + 1
  end
end

function get_context(file, desc)
  list = io.open(file, "r");
  list:seek("set")
  values = {}
  i = 1
  while i <= num_tests do
    values[i] = {}
    i = i + 1
  end
  c = -1
  z = 1
  for l in list:lines() do
    a = string.match(l, "^(Context) switching");
    if(a) then
      c = 0
    elseif(c >= 4 + num_tests) then
      c = -1
    elseif(c >= 4) then
      values[c - 3]["host"] = string.gsub(string.sub(l,1,8)," ","")
      values[c - 3]["OS"] = string.gsub(string.sub(l,10,23)," ","")
      values[c - 3]["2p0"] = format(string.sub(l,25,30))
      values[c - 3]["2p16"] = format(string.sub(l,32,37))
      values[c - 3]["2p64"] = format(string.sub(l,39,44))
      values[c - 3]["8p16"] = format(string.sub(l,46,51))
      values[c - 3]["8p64"] = format(string.sub(l,53,58))
      values[c - 3]["16p16"] = format(string.sub(l,60,66))
      values[c - 3]["16p64"] = format(string.sub(l,68,76))
      c = c + 1
    elseif(c >= 0) then
      c = c + 1
    end
  end
  i = 1
  if file == arg[1] then
    print("\n\n\n\n\n\nContext switching - times in microseconds - smaller is better")
    print("description,host,OS,2p/0K ctxsw,2p/16K ctxsw,2p/64K ctxsw,8p/16K ctxsw,8p/64K ctxsw,16p/16K ctxsw, 16p/64K ctxsw")
  end
  while i <= num_tests  do
    print(desc .. "," .. values[i]["host"] .. "," .. values[i]["OS"] .. "," .. values[i]["2p0"] .. "," .. values[i]["2p16"] .. "," .. values[i]["2p64"] .. "," .. values[i]["8p16"] .. "," .. values[i]["8p64"] .. "," .. values[i]["16p16"] .. "," .. values[i]["16p64"])
    i = i + 1
  end
end

function get_localcomm(file, desc)
  list = io.open(file, "r");
  list:seek("set")
  values = {}
  i = 1
  while i <= num_tests do
    values[i] = {}
    i = i + 1
  end
  c = -1
  z = 1
  for l in list:lines() do
    a = string.match(l, "^(%*Local%*) Communication.*latencies");
    if(a) then
      c = 0
    elseif(c >= 4 + num_tests) then
      c = -1
    elseif(c >= 4) then
      values[c - 3]["host"] = string.gsub(string.sub(l,1,8)," ","")
      values[c - 3]["OS"] = string.gsub(string.sub(l,10,23)," ","")
      values[c - 3]["2p0"] = format(string.sub(l,25,29))
      values[c - 3]["pipe"] = format(string.sub(l,31,35))
      values[c - 3]["afunix"] = format(string.sub(l,37,40))
      values[c - 3]["udp"] = format(string.sub(l,42,46))
      values[c - 3]["rpcudp"] = format(string.sub(l,48,52))
      values[c - 3]["tcp"] = format(string.sub(l,54,58))
      values[c - 3]["rpctcp"] = format(string.sub(l,60,64))
      values[c - 3]["tcpconn"] = format(string.sub(l,66,70))
      c = c + 1
    elseif(c >= 0) then
      c = c + 1
    end
  end
  i = 1
  if file == arg[1] then
    print("\n\n\n\n\n\n*Local* Communication latencies in microseconds - smaller is better")
    print("description,host,OS,2p/0K,Pipe,AF UNIX,UDP,RPC/UDP,TCP,RPC/TCP,TCP conn")
  end
  while i <=  num_tests  do
    print(desc .. "," .. values[i]["host"] .. "," .. values[i]["OS"] .. "," .. values[i]["2p0"] .. "," .. values[i]["pipe"] .. "," .. values[i]["afunix"] .. "," .. values[i]["udp"] .. "," .. values[i]["rpcudp"] .. "," .. values[i]["tcp"] .. "," .. values[i]["rpctcp"] .. "," .. values[i]["tcpconn"])
    i = i + 1
  end
end

function get_filevm(file, desc)
  list = io.open(file, "r");
  list:seek("set")
  values = {}
  i = 1
  while i <= num_tests do
    values[i] = {}
    i = i + 1
  end
  c = -1
  z = 1
  for l in list:lines() do
    a = string.match(l, "^File.*latencies");
    if(a) then
      c = 0
    elseif(c >= 4 + num_tests) then
      c = -1
    elseif(c >= 4) then
      values[c - 3]["host"] = string.gsub(string.sub(l,1,8)," ","")
      values[c - 3]["OS"] = string.gsub(string.sub(l,10,23)," ","")
      values[c - 3]["0kcreate"] = format(string.sub(l,25,30))
      values[c - 3]["0kdelete"] = format(string.sub(l,32,37))
      values[c - 3]["10kcreate"] = format(string.sub(l,39,44))
      values[c - 3]["10kdelete"] = format(string.sub(l,46,51))
      values[c - 3]["mmap"] = format(string.sub(l,53,59))
      values[c - 3]["protfault"] = format(string.sub(l,61,65))
      values[c - 3]["pagefault"] = format(string.sub(l,67,73))
      values[c - 3]["100fdselct"] = format(string.sub(l,75,79))
      c = c + 1
    elseif(c >= 0) then
      c = c + 1
    end
  end
  i = 1
  if file == arg[1] then
    print("\n\n\n\n\n\nFile & VM system latencies in microseconds - smaller is better")
    print("description,host,OS,0K File Create,0K File Delete,10K File Create,10K File Delete,Mmap Latency,Prot Fault,Page Fault,100fd selct")
  end
  while i <= num_tests  do
    print(desc .. "," .. values[i]["host"] .. "," .. values[i]["OS"] .. "," .. values[i]["0kcreate"] .. "," .. values[i]["0kdelete"] .. "," .. values[i]["10kcreate"] .. "," .. values[i]["10kdelete"] .. "," .. values[i]["mmap"] .. "," .. values[i]["protfault"] .. "," .. values[i]["pagefault"] .. "," .. values[i]["100fdselct"])
    i = i + 1
  end
end

function get_localcommbwd(file, desc)
  list = io.open(file, "r");
  list:seek("set")
  values = {}
  i = 1
  while i <= num_tests do
    values[i] = {}
    i = i + 1
  end
  c = -1
  z = 1
  for l in list:lines() do
    a = string.match(l, "^(%*Local%*) Communication.*bandwidth");
    if(a) then
      c = 0
    elseif(c >= 4 + num_tests) then
      c = -1
    elseif(c >= 4) then
      values[c - 3]["host"] = string.gsub(string.sub(l,1,8)," ","")
      values[c - 3]["OS"] = string.gsub(string.sub(l,10,23)," ","")
      values[c - 3]["pipe"] = format(string.sub(l,25,28))
      values[c - 3]["afunix"] = format(string.sub(l,30,33))
      values[c - 3]["tcp"] = format(string.sub(l,35,38))
      values[c - 3]["filereread"] = format(string.sub(l,40,45))
      values[c - 3]["mmapreread"] = format(string.sub(l,47,52))
      values[c - 3]["bcopylibc"] = format(string.sub(l,54,59))
      values[c - 3]["bcopyhand"] = format(string.sub(l,61,66))
      values[c - 3]["memread"] = format(string.sub(l,68,71))
      values[c - 3]["memwrite"] = format(string.sub(l,73,77))
      c = c + 1
    elseif(c >= 0) then
      c = c + 1
    end
  end
  i = 1
  if file == arg[1] then
    print("\n\n\n\n\n\n*Local* Communication bandwidths in MB/s - bigger is better")
    print("description,host,OS,Pipe,AF UNIX,TCP,File reread,Mmap reread,Bcopy (libc),Bcopy (hand),Mem read,Mem write")
  end
  while i <= num_tests  do
    print(desc .. "," .. values[i]["host"] .. "," .. values[i]["OS"] .. "," .. values[i]["pipe"] .. "," .. values[i]["afunix"] .. "," .. values[i]["tcp"] .. "," .. values[i]["filereread"] .. "," .. values[i]["mmapreread"] .. "," .. values[i]["bcopylibc"] .. "," .. values[i]["bcopyhand"] .. "," .. values[i]["memread"] .. "," .. values[i]["memwrite"])
    i = i + 1
  end
end

if(#arg % 2 == 1) then
  print("please, use: lua parse_lmbench.lua file descrpt file descrpt...");
  os.exit()
end
r = 1
while r <= #arg do
  get_proc(arg[r], arg[r+1])
  r = r + 2
end
r = 1
while r <= #arg do
  get_context(arg[r], arg[r+1])
  r = r + 2
end
r = 1
while r <= #arg do
  get_localcomm(arg[r], arg[r+1])
  r = r + 2
end
r = 1
while r <= #arg do
  get_filevm(arg[r], arg[r+1])
  r = r + 2
end
r = 1
while r <= #arg do
  get_localcommbwd(arg[r], arg[r+1])
  r = r + 2
end
