require 'zabby'
require 'json'
require 'active_support/core_ext/numeric/time'
require 'clockwork'

module Clockwork
  handler do |job|
    swarn = []
    savrg = []
    shgh = []
    sdis = []

    twarn = 0
    tavrg = 0
    thgh = 0
    tdis = 0

    sum = 0

    lav_warn = 0
    lav_avrg = 0
    lav_hgh = 0
    lav_dis = 0

    serv = Zabby.init do
      set :server => "http://192.168.1.10/zabbix"
      set :user => "admin"
      set :password => "zabbix"
      login
    end

    env = serv.run { Zabby::Trigger.get "filter" => { "priority" => [ 2, 3, 4, 5 ] }, "output" => "extend", "only_true" => "true", "monitored" => 1, "withUnacknowledgedEvents" => 1, "skipDependent" => 1, "expandData" => "host" }

    pas = JSON.parse(env.to_json)

    pas.each do |res|
      prio = res["priority"]
      lstchnge = res["lastchange"]
      hostnme = res["hostname"]
      alertime = Time.at(lstchnge.to_i)

      # adjust the pref. time
      # timelapse = Time.now - 1.hours
      timelapse = Time.now - (90 * 24).hours

      if alertime >= timelapse
        case prio
        when '2' then
          swarn << hostnme
        when '3' then
          savrg << hostnme
        when '4' then
          shgh << hostnme
        when '5' then
          sdis << hostnme
        end
      end
    end

    lav_warn = twarn
    lav_avrg = tavrg
    lav_hgh = thgh
    lav_dis = tdis

    twarn = swarn.count
    tavrg = savrg.count
    thgh = shgh.count
    tdis = sdis.count

    warn = twarn - lav_warn
    avrg = tavrg - lav_avrg
    hgh = thgh - lav_hgh
    dis = tdis - lav_dis

    if warn > 0 then warnstats = "warn" else warnstats = "ok" end
    if avrg > 0 then avrgstats = "average" else avrgstats = "ok" end
    if hgh > 0 then hghstats = "high" else hghstats = "ok" end
    if dis > 0 then disstats = "disaster" else disstats = "ok" end

    sum = warn + avrg + hgh + dis
    puts "warn is #{warn}"
    puts "avrg is #{avrg}"
    puts "hgh is #{hgh}"
    puts "dis is #{dis}"
    puts "sum is #{sum}"

    if sum != 0
      system('rsh 192.168.1.1 -l root ACOP 20010000')
    end
        end

  every(1.minutes, 'zabbix_check.job')
end
