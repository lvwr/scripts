#!/usr/bin/lua

function parse(sim_file)
  report = {}
  core = {}
  core_power = {}
  bus_power = {}
  core_energy = {}
  energy_sum = {}
  sim_names = {}
  for line in sim_file:lines() do
    simulation, cores, path, params = string.match(line, "^(%a+%p?%a+%d?%p?%p?)%s(%d*)%s([%p%a*%d*]*)%s(\#.*\#)")
    if simulation then
      typ = string.match(path, "^.*(lock).*$")
      if not typ then
        typ = string.match(path, "^.*(seq).*$")
      end
      print(typ)
      simname = simulation .. cores .. "-" .. typ
      sim_names[#sim_names+1] = simname
      cores = tonumber(cores)
      report[simname] = {}
      path = path .. "/" .. simulation .. "-" .. cores .. "c.txt"
      o_file = io.open(path,"r")
      if not o_file then
        print("Error: Invalid path, couldn't open report. " .. simulation .. cores)
        print(path)
        os.exit()
      end
      output_file = o_file.read(o_file, "*all")
      minutes = string.match(output_file, "Elapsed time %- overall simulation: (%d*)%p%d%d%s")
      seconds = string.match(output_file, "Elapsed time %- overall simulation: %d*%p(%d%d)%s")
      report[simname]["simulation_time"] = minutes * 60 + seconds
      report[simname]["cycles"], report[simname]["ns"] = string.match(output_file, "Total simulated master system cycles: (%d*) %((%d*) ns%)")
      report[simname]["cyclesps"] = string.match(output_file, "CPU cycles simulated per second: (%d*%p?%d*)")
      report[simname]["cores"] = cores
      report[simname]["core_data"] = {}
      print("Simulation: " .. simulation .. cores)
      i = 0
      while(i < cores) do
        print("Core: " .. i )
        pattern = "Processor " .. i .. "(.*)"
        pattern = pattern .. "%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-"
        pattern = pattern .. "%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-"
        pattern = pattern .. "%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-"
        proc_data = string.match(output_file, pattern)
        report[simname]["core_data"][i] = {}
        report[simname]["core_data"][i]["private_r"] = string.match(proc_data, "Private reads%s*|%c*%s*(%d*)")
        report[simname]["core_data"][i]["private_w"] = string.match(proc_data, "Private writes%s*|%c*%s*(%d*)")
        report[simname]["core_data"][i]["shared_r"] = string.match(proc_data, "Shared reads%s*|%c*%s*(%d*)")
        report[simname]["core_data"][i]["shared_w"] = string.match(proc_data, "Shared writes%s*|%c*%s*(%d*)")
        report[simname]["core_data"][i]["semaphore_r"] = string.match(proc_data, "Semaphore reads%s*|%c*%s*(%d*)")
        report[simname]["core_data"][i]["semaphore_w"] = string.match(proc_data, "Semaphore writes%s*|%c*%s*(%d*)")
        report[simname]["core_data"][i]["internal_r"] = string.match(proc_data, "Internal reads%s*|%c*%s*(%d*)")
        report[simname]["core_data"][i]["internal_w"] = string.match(proc_data, "Internal writes%s*|%c*%s*(%d*)")
        report[simname]["core_data"][i]["dcache_r_hits"] = string.match(proc_data, "D%-Cache: (%d*)%sread%shits")
        report[simname]["core_data"][i]["dcache_w_hits"] = string.match(proc_data, "D%-Cache: (%d*)%swrite%-through%shits")
        report[simname]["core_data"][i]["dcache_r_miss"] = string.match(proc_data, "D%-Cache: %d*%sread%shits;%s(%d*)%sread%smisses")
        report[simname]["core_data"][i]["dcache_w_miss"] = string.match(proc_data, "D%-Cache: %d*%swrite%-through%shits;%s(%d*)%swrite%-through%smisses")
        report[simname]["core_data"][i]["dcache_miss_rate"] = string.match(proc_data, "D%-Cache%sMiss%sRate: (%d*%p%d*)")
        report[simname]["core_data"][i]["icache_r_hits"] = string.match(proc_data, "I%-Cache: (%d*)%sread%shits")
        report[simname]["core_data"][i]["icache_w_hits"] = string.match(proc_data, "I%-Cache: (%d*)%swrite%-through%shits")
        report[simname]["core_data"][i]["icache_r_miss"] = string.match(proc_data, "I%-Cache: %d*%sread%shits;%s(%d*)%sread%smisses")
        report[simname]["core_data"][i]["icache_w_miss"] = string.match(proc_data, "I%-Cache: %d*%swrite%-through%shits;%s(%d*)%swrite%-through%smisses")
        report[simname]["core_data"][i]["icache_miss_rate"] = string.match(proc_data, "I%-Cache%sMiss%sRate: (%d*%p%d*)")
        i = i + 1
      end
      pattern = "Energy spent(.*)"
      pattern = pattern .. "%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-"
      pattern = pattern .. "%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-"
      pattern = pattern .. "%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-"
      proc_data = string.match(output_file, pattern)
      i = 0
      while(i < cores) do
        report[simname]["core_energy"] = {}
        report[simname]["core_energy"]["core"] = string.match(proc_data, "ARM " .. i .. ":.-core:%c*%s*(%d*%p%d*)")
        report[simname]["core_energy"]["icache"] = string.match(proc_data, "ARM " .. i .. ":.-icache:%c*%s*(%d*%p%d*)")
        report[simname]["core_energy"]["dcache"] = string.match(proc_data, "ARM " .. i .. ":.-dcache:%c*%s*(%d*%p%d*)")
        i = i + 1
      end
      report[simname]["sum_energy"] = {}
      pattern = "Partial sums:(.*)"
      pattern = pattern .. "%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-"
      pattern = pattern .. "%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-"
      pattern = pattern .. "%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-"
      proc_data = string.match(output_file, pattern)
      report[simname]["sum_energy"]["cores"] = string.match(proc_data, "ARM cores:%c*%s*(%d*%p%d*)")
      report[simname]["sum_energy"]["icaches"] = string.match(proc_data, "icaches:%c*%s*(%d*%p%d*)")
      report[simname]["sum_energy"]["dcaches"] = string.match(proc_data, "dcaches:%c*%s*(%d*%p%d*)")
      report[simname]["sum_energy"]["RAMs"] = string.match(proc_data, "RAMs:%c*%s*(%d*%p%d*)")
      report[simname]["sum_energy"]["bus_typ"] = string.match(proc_data, "Buses:.-typ:%c*%s*(%d*%p%d*)")
      if not report[simname]["sum_energy"]["bus_typ"] then
        report[simname]["sum_energy"]["bus_typ"] = "nan"
      end
      report[simname]["sum_energy"]["bus_max"] = string.match(proc_data, "Buses:.-max:%c*%s*(%d*%p%d*)")
      report[simname]["sum_energy"]["bus_min"] = string.match(proc_data, "Buses:.-min:%c*%s*(%d*%p%d*)")
      if not report[simname]["sum_energy"]["bus_min"] then
        report[simname]["sum_energy"]["bus_min"] = "nan"
      end
      report[simname]["sum_energy"]["total_typ"] = string.match(proc_data, "Total:.-(%d+%p%d+).-typ")
      if not report[simname]["sum_energy"]["total_typ"] then
        report[simname]["sum_energy"]["total_typ"] = "nan"
      end
      report[simname]["sum_energy"]["total_max"] = string.match(proc_data, "Total:.-(%d+%p%d+).-max")
      if not report[simname]["sum_energy"]["total_max"] then
        report[simname]["sum_energy"]["total_max"] = "nan"
      end
      report[simname]["sum_energy"]["total_min"] = string.match(proc_data, "Total:.-(%d+%p%d+).-min")
      if not report[simname]["sum_energy"]["total_min"] then
        report[simname]["sum_energy"]["total_min"] = "nan"
      end

      -- parsing power spent

      pattern = "Power spent(.*)"
      proc_data = string.match(output_file, pattern)
      i = 0
      report[simname]["core_power"] = {}
      while(i < cores) do
        report[simname]["core_power"][i] = {}
        report[simname]["core_power"][i]["core"] = string.match(proc_data, "ARM " .. i .. ":.-core:%c*%s*(%d*%p%d*)")
        report[simname]["core_power"][i]["icache"] = string.match(proc_data, "ARM " .. i .. ":.-icache:%c*%s*(%d*%p%d*)")
        report[simname]["core_power"][i]["dcache"] = string.match(proc_data, "ARM " .. i .. ":.-dcache:%c*%s*(%d*%p%d*)")
        i = i + 1
      end
      report[simname]["bus_power"] = {}
      report[simname]["bus_power"]["typ"] = string.match(proc_data, "Bus 0:.-typ:.-(%d+%p%d+)")
      if not report[simname]["bus_power"]["typ"] then
        report[simname]["bus_power"]["typ"] = "nan"
      end
      report[simname]["bus_power"]["max"] = string.match(proc_data, "Bus 0:.-max:.-(%d*%p%d*)")
      report[simname]["bus_power"]["min"] = string.match(proc_data, "Bus 0:.-min:.-(%d+%p%d+)")
      if not report[simname]["bus_power"]["min"] then
        report[simname]["bus_power"]["min"] = "nan"
      end
    end
  end
  return report, sim_names
end

function create_csv(report_ac, report_sw, names)
  output = "simulation_name, core, attribute, ArchC, SWARM, Difference, Obs\n"
  for i, sim in ipairs(names) do
    print(sim)
    output = output .. ",,,,,,\n"
    p = speedup(report_ac[sim]["simulation_time"], report_sw[sim]["simulation_time"])
    line = sim .. ", _".. ", simulation time, " .. report_ac[sim]["simulation_time"] .. ", " .. report_sw[sim]["simulation_time"] .. ", " .. p .. "\n"
    output = output .. line
    p = percent(report_ac[sim]["cycles"], report_sw[sim]["cycles"])
    line = sim .. ", _".. ", cycles, " .. report_ac[sim]["cycles"] .. ", " .. report_sw[sim]["cycles"] .. ", " .. p .. "\n"
    output = output .. line
    p = percent(report_ac[sim]["cyclesps"], report_sw[sim]["cyclesps"])
    line = sim .. ", _".. ", cycles p/ s, " .. report_ac[sim]["cyclesps"] .. ", " .. report_sw[sim]["cyclesps"] .. ", " .. p .. "\n"
    output = output .. line
    line = ",,,,,,\n"
    output = output .. line
    p = percent(report_ac[sim]["sum_energy"]["cores"], report_sw[sim]["sum_energy"]["cores"])
    line = sim .. ", _".. ", total core energy, " .. report_ac[sim]["sum_energy"]["cores"] .. ", " .. report_sw[sim]["sum_energy"]["cores"] .. ", " .. p .. "\n"
    output = output .. line
    p = percent(report_ac[sim]["sum_energy"]["icaches"], report_sw[sim]["sum_energy"]["icaches"])
    line = sim .. ", _".. ", total ICaches energy, " .. report_ac[sim]["sum_energy"]["icaches"] .. ", " .. report_sw[sim]["sum_energy"]["icaches"] .. ", " .. p .. "\n"
    output = output .. line
    p = percent(report_ac[sim]["sum_energy"]["icaches"], report_sw[sim]["sum_energy"]["icaches"])
    line = sim .. ", _".. ", total DCaches energy, " .. report_ac[sim]["sum_energy"]["icaches"] .. ", " .. report_sw[sim]["sum_energy"]["icaches"] .. ", " .. p .. "\n"
    output = output .. line
    p = percent(report_ac[sim]["sum_energy"]["RAMs"], report_sw[sim]["sum_energy"]["RAMs"])
    line = sim .. ", _".. ", total RAM energy, " .. report_ac[sim]["sum_energy"]["RAMs"] .. ", " .. report_sw[sim]["sum_energy"]["RAMs"] .. ", " .. p .. "\n"
    output = output .. line
    p = percent(report_ac[sim]["sum_energy"]["bus_typ"], report_sw[sim]["sum_energy"]["bus_typ"])
    line = sim .. ", _".. ", total Bus typ energy, " .. report_ac[sim]["sum_energy"]["bus_typ"] .. ", " .. report_sw[sim]["sum_energy"]["bus_typ"] .. ", " .. p .. "\n"
    output = output .. line
    p = percent(report_ac[sim]["sum_energy"]["bus_max"], report_sw[sim]["sum_energy"]["bus_max"])
  line = sim .. ", _".. ", total Bus max energy, " .. report_ac[sim]["sum_energy"]["bus_max"] .. ", " .. report_sw[sim]["sum_energy"]["bus_max"] .. ", " .. p .. "\n"
    output = output .. line
    p = percent(report_ac[sim]["sum_energy"]["bus_min"], report_sw[sim]["sum_energy"]["bus_min"])
    line = sim .. ", _".. ", total Bus min energy, " .. report_ac[sim]["sum_energy"]["bus_min"] .. ", " .. report_sw[sim]["sum_energy"]["bus_min"] .. ", " .. p .. "\n"
    output = output .. line
    p = percent(report_ac[sim]["sum_energy"]["total_typ"], report_sw[sim]["sum_energy"]["total_typ"])
    line = sim .. ", _".. ", total energy typ, " .. report_ac[sim]["sum_energy"]["total_typ"] .. ", " .. report_sw[sim]["sum_energy"]["total_typ"] .. ", " .. p .. "\n"
    output = output .. line
    p = percent(report_ac[sim]["sum_energy"]["total_max"], report_sw[sim]["sum_energy"]["total_max"])
    line = sim .. ", _".. ", total energy max, " .. report_ac[sim]["sum_energy"]["total_max"] .. ", " .. report_sw[sim]["sum_energy"]["total_max"] .. ", " .. p .. "\n"
    output = output .. line
    p = percent(report_ac[sim]["sum_energy"]["total_min"], report_sw[sim]["sum_energy"]["total_min"])
    line = sim .. ", _".. ", total energy min, " .. report_ac[sim]["sum_energy"]["total_min"] .. ", " .. report_sw[sim]["sum_energy"]["total_min"] .. ", " .. p .. "\n"
    output = output .. line
    line = ",,,,,,\n"
    output = output .. line
    p = percent(report_ac[sim]["bus_power"]["typ"], report_sw[sim]["bus_power"]["typ"])
    line = sim .. ", _".. ", total Bus power typ, " .. report_ac[sim]["bus_power"]["typ"] .. ", " .. report_sw[sim]["bus_power"]["typ"] .. ", " .. p .. "\n"
    output = output .. line
    p = percent(report_ac[sim]["bus_power"]["max"], report_sw[sim]["bus_power"]["max"])
    line = sim .. ", _".. ", total Bus power max, " .. report_ac[sim]["bus_power"]["max"] .. ", " .. report_sw[sim]["bus_power"]["max"] .. ", " .. p .. "\n"
    output = output .. line
    p = percent(report_ac[sim]["bus_power"]["min"], report_sw[sim]["bus_power"]["min"])
    line = sim .. ", _".. ", total Bus power min, " .. report_ac[sim]["bus_power"]["min"] .. ", " .. report_sw[sim]["bus_power"]["min"] .. ", " .. p .. "\n"
    output = output .. line
    line = ",,,,,,\n"
    output = output .. line
    i = 0
    while i < report_ac[sim]["cores"] do
      p = percent(report_ac[sim]["core_power"][i]["core"], report_sw[sim]["core_power"][i]["core"])
      line = sim .. ", " .. i .. ", Core power, " .. report_ac[sim]["core_power"][i]["core"] .. ", " .. report_sw[sim]["core_power"][i]["core"] .. ", " .. p .. "\n"
      output = output .. line
      p = percent(report_ac[sim]["core_power"][i]["dcache"], report_sw[sim]["core_power"][i]["dcache"])
      line = sim .. ", " .. i .. ", DCache power, " .. report_ac[sim]["core_power"][i]["dcache"] .. ", " .. report_sw[sim]["core_power"][i]["dcache"] .. ", " .. p .. "\n"
      output = output .. line
      p = percent(report_ac[sim]["core_power"][i]["icache"], report_sw[sim]["core_power"][i]["icache"])
      line = sim .. ", " .. i .. ", ICache power, " .. report_ac[sim]["core_power"][i]["icache"] .. ", " .. report_sw[sim]["core_power"][i]["icache"] .. ", " .. p .. "\n"
      output = output .. line
      i = i + 1
    end
    i = 0
    while i < report_ac[sim]["cores"] do
      p = percent(report_ac[sim]["core_data"][i]["private_r"], report_sw[sim]["core_data"][i]["private_r"])
      line = sim .. ", " .. i .. ", Private Reads, " .. report_ac[sim]["core_data"][i]["private_r"] .. ", " .. report_sw[sim]["core_data"][i]["private_r"] .. ", " .. p .. "\n"
      output = output .. line
      p = percent(report_ac[sim]["core_data"][i]["private_w"], report_sw[sim]["core_data"][i]["private_w"])
      line = sim .. ", " .. i .. ", Private Writes, " .. report_ac[sim]["core_data"][i]["private_w"] .. ", " .. report_sw[sim]["core_data"][i]["private_w"] .. ", " .. p .. "\n"
      output = output .. line
      p = percent(report_ac[sim]["core_data"][i]["shared_r"], report_sw[sim]["core_data"][i]["shared_r"])
      line = sim .. ", " .. i .. ", Shared Reads, " .. report_ac[sim]["core_data"][i]["shared_r"] .. ", " .. report_sw[sim]["core_data"][i]["shared_r"] .. ", " .. p .. "\n"
      output = output .. line
      p = percent(report_ac[sim]["core_data"][i]["shared_w"], report_sw[sim]["core_data"][i]["shared_w"])
      line = sim .. ", " .. i .. ", Shared Writes, " .. report_ac[sim]["core_data"][i]["shared_w"] .. ", " .. report_sw[sim]["core_data"][i]["shared_w"] .. ", " .. p .. "\n"
      output = output .. line
      p = percent(report_ac[sim]["core_data"][i]["semaphore_r"], report_sw[sim]["core_data"][i]["semaphore_r"])
      line = sim .. ", " .. i .. ", Semaphore Reads, " .. report_ac[sim]["core_data"][i]["semaphore_r"] .. ", " .. report_sw[sim]["core_data"][i]["semaphore_r"] .. ", " .. p .. "\n"
      output = output .. line
      p = percent(report_ac[sim]["core_data"][i]["semaphore_w"], report_sw[sim]["core_data"][i]["semaphore_w"])
      line = sim .. ", " .. i .. ", Semaphore Writes, " .. report_ac[sim]["core_data"][i]["semaphore_w"] .. ", " .. report_sw[sim]["core_data"][i]["semaphore_w"] .. ", " .. p .. "\n"
      output = output .. line
      p = percent(report_ac[sim]["core_data"][i]["internal_r"], report_sw[sim]["core_data"][i]["internal_r"])
      line = sim .. ", " .. i .. ", Internal Reads, " .. report_ac[sim]["core_data"][i]["internal_r"] .. ", " .. report_sw[sim]["core_data"][i]["internal_r"] .. ", " .. p .. "\n"
      output = output .. line
      p = percent(report_ac[sim]["core_data"][i]["internal_w"], report_sw[sim]["core_data"][i]["internal_w"])
      line = sim .. ", " .. i .. ", Internal Writes, " .. report_ac[sim]["core_data"][i]["internal_w"] .. ", " .. report_sw[sim]["core_data"][i]["internal_w"] .. ", " .. p .. "\n"
      output = output .. line
      p = percent(report_ac[sim]["core_data"][i]["dcache_r_hits"], report_sw[sim]["core_data"][i]["dcache_r_hits"])
      line = sim .. ", " .. i .. ", DCache Read Hits, " .. report_ac[sim]["core_data"][i]["dcache_r_hits"] .. ", " .. report_sw[sim]["core_data"][i]["dcache_r_hits"] .. ", " .. p .. "\n"
      output = output .. line
      p = percent(report_ac[sim]["core_data"][i]["dcache_w_hits"], report_sw[sim]["core_data"][i]["dcache_w_hits"])
      line = sim .. ", " .. i .. ", DCache Write Hits, " .. report_ac[sim]["core_data"][i]["dcache_w_hits"] .. ", " .. report_sw[sim]["core_data"][i]["dcache_w_hits"] .. ", " .. p .. "\n"
      output = output .. line
      p = percent(report_ac[sim]["core_data"][i]["dcache_r_miss"], report_sw[sim]["core_data"][i]["dcache_r_miss"])
      line = sim .. ", " .. i .. ", DCache Read Misses, " .. report_ac[sim]["core_data"][i]["dcache_r_miss"] .. ", " .. report_sw[sim]["core_data"][i]["dcache_r_miss"] .. ", " .. p .. "\n"
      output = output .. line
      p = percent(report_ac[sim]["core_data"][i]["dcache_w_miss"], report_sw[sim]["core_data"][i]["dcache_w_miss"])
      line = sim .. ", " .. i .. ", DCache Write Misses, " .. report_ac[sim]["core_data"][i]["dcache_w_miss"] .. ", " .. report_sw[sim]["core_data"][i]["dcache_w_miss"] .. ", " .. p .. "\n"
      output = output .. line
      p = percent(report_ac[sim]["core_data"][i]["dcache_miss_rate"], report_sw[sim]["core_data"][i]["dcache_miss_rate"])
      line = sim .. ", " .. i .. ", DCache Miss Rate, " .. report_ac[sim]["core_data"][i]["dcache_miss_rate"] .. ", " .. report_sw[sim]["core_data"][i]["dcache_miss_rate"] .. ", " .. p .. "\n"
      output = output .. line
      p = percent(report_ac[sim]["core_data"][i]["icache_r_hits"], report_sw[sim]["core_data"][i]["icache_r_hits"])
      line = sim .. ", " .. i .. ", ICache Read Hits, " .. report_ac[sim]["core_data"][i]["icache_r_hits"] .. ", " .. report_sw[sim]["core_data"][i]["icache_r_hits"] .. ", " .. p .. "\n"
      output = output .. line
      p = percent(report_ac[sim]["core_data"][i]["icache_w_hits"], report_sw[sim]["core_data"][i]["icache_w_hits"])
      line = sim .. ", " .. i .. ", ICache Write Hits, " .. report_ac[sim]["core_data"][i]["icache_w_hits"] .. ", " .. report_sw[sim]["core_data"][i]["icache_w_hits"] .. ", " .. p .. "\n"
      output = output .. line
      p = percent(report_ac[sim]["core_data"][i]["icache_r_miss"], report_sw[sim]["core_data"][i]["icache_r_miss"])
      line = sim .. ", " .. i .. ", ICache Read Misses, " .. report_ac[sim]["core_data"][i]["icache_r_miss"] .. ", " .. report_sw[sim]["core_data"][i]["icache_r_miss"] .. ", " .. p .. "\n"
      output = output .. line
      p = percent(report_ac[sim]["core_data"][i]["icache_w_miss"], report_sw[sim]["core_data"][i]["icache_w_miss"])
      line = sim .. ", " .. i .. ", ICache Write Misses, " .. report_ac[sim]["core_data"][i]["icache_w_miss"] .. ", " .. report_sw[sim]["core_data"][i]["icache_w_miss"] .. ", " .. p .. "\n"
      output = output .. line
      p = percent(report_ac[sim]["core_data"][i]["icache_miss_rate"], report_sw[sim]["core_data"][i]["icache_miss_rate"])
      line = sim .. ", " .. i .. ", ICache Miss Rate, " .. report_ac[sim]["core_data"][i]["icache_miss_rate"] .. ", " .. report_sw[sim]["core_data"][i]["icache_miss_rate"] .. ", " .. p .. "\n"
      output = output .. line
      i = i + 1
    end
  end
  sim_report = io.open("mparm_report.csv","w")
  sim_report.write(sim_report, output)
  sim_report.flush(sim_report)
end

function speedup(value1, value2)
  return tonumber(value2)/tonumber(value1)
end

function percent(value1, value2)
  if value1 == "nan" or value2 == "nan" then
    return 0
  end
  return tonumber(value1)*100/tonumber(value2)
end

sim_file = io.open(arg[1],"r")
if not sim_file then
  os.exit()
end
report_ac, names = parse(sim_file)
sim_file = io.open(arg[2],"r")
if not sim_file then
  os.exit()
end
report_swarm = parse(sim_file)

create_csv(report_ac, report_swarm, names)
