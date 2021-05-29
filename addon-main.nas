#This file is part of FlightGear.
#
#FlightGear is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 2 of the License, or
#(at your option) any later version.
#
#FlightGear is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with FlightGear.  If not, see <http://www.gnu.org/licenses/>.

# This is the main addon Nasal hook. It MUST contain a function
# called "main". The main function will be called upon init with
# the addons.Addon instance corresponding to the addon being loaded.
#
# This script will live in its own Nasal namespace that gets
# dynamically created from the global addon init script.
# It will be something like "__addon[ADDON_ID]__" where ADDON_ID is
# the addon identifier, such as "org.flightgear.addons.Skeleton".
#
# See $FG_ROOT/Docs/README.add-ons for info about the addons.Addon
# object that is passed to main(), and much more. The latest version
# of this README.add-ons document is at:
#
#   https://sourceforge.net/p/flightgear/fgdata/ci/next/tree/Docs/README.add-ons
#

#
# Author: D. Meissner (danielHL.83@googlemail.com)
#
# Based on landing-rate addon by RenanMsV (https://github.com/RenanMsV/landing_rate)
#

#var tgt_width = 20;

var PROP_PATH = "/addons/by-id/org.flightgear.addons.landing-challenge/addon-devel/";

var tgt_pos = nil;
var rwy = nil;

var window = screen.window.new(10, 10, 3, 10); # create new window object. 750, 10 : Lower Right
window.bg = [0,0,0,.5]; # black alpha .5 background

# Find runway and set up target models
var setup_runway = func(addon) {
    var tgt_apt = getprop(PROP_PATH ~ "airport");
    var tgt_rwy = getprop(PROP_PATH ~ "runway");
    var tgt_dst = getprop(PROP_PATH ~ "target-dist-m");
    
    
    # get information about selected airport
    apt = airportinfo(tgt_apt);
    
    # find selected runway
    foreach (var r; keys(apt.runways)) {
		var curr = apt.runways[r];

		if (apt.runways[r].id == tgt_rwy) {
			rwy = curr;
			break;
		}
	}
	
	# the landing target position
	var tgt_pos = geo.Coord.new();
	tgt_pos.set_latlon(rwy.lat, rwy.lon);
    
    #offset the target distance from threshold
    tgt_pos.apply_course_distance(rwy.heading, tgt_dst);
    
    tgt_pos.set_alt(geo.elevation(tgt_pos.lat(), tgt_pos.lon()));
    
    # place the chalk markings for the landing area on the runway
    var markings = geo.put_model(addon.basePath~"/Models/markings-ga.xml", tgt_pos, rwy.heading);
    print("tgt elevation: " ~ sprintf("%.3f", geo.elevation(tgt_pos.lat(), tgt_pos.lon())));
        
    var conepos = geo.Coord.new(tgt_pos);
        var left = 0;
    var right = 0;
    
    if(rwy.heading - 90 < 0) {
        left = rwy.heading - 90 + 360;
    } else {
        left = rwy.heading - 90;
    }    
    if(rwy.heading + 90 > 360) {
        right = rwy.heading + 90 - 360;
    } else {
        right = rwy.heading + 90;
    }
    
    #place the cones for tdz-area
    for(var i=1; i<4; i=i+1) {
        conepos.set(tgt_pos);
        conepos.apply_course_distance(left, 12.5 + 0.5*i);
        var cone = geo.put_model(addon.basePath~"/Models/cone.xml", conepos);
        conepos.set(tgt_pos);
        conepos.apply_course_distance(right, 12.5 + 0.5*i);
        var cone = geo.put_model(addon.basePath~"/Models/cone.xml", conepos);
	}
	
	return tgt_pos;
}

var init_landing_rate_timer = func {
    # gear props array
	gear_props = ["gear/gear[0]/wow", "gear/gear[1]/wow", "gear/gear[2]/wow"]; 
    # status props array
	landing_props = [PROP_PATH ~ "landed", PROP_PATH ~ "altTrig"];
	
	# init addon props array
	forindex (var i; landing_props) 
        props.globals.initNode(landing_props[i], 0, nil); 
        
    # set gear props listeners
	forindex(var i; gear_props) 
        setlistener(gear_props[i], func(n) {
            if(n.getValue() and !getprop(PROP_PATH ~ "landed")) {
                setprop(PROP_PATH ~ "landed", 1); 
            } else {
                setprop(PROP_PATH ~ "landed", 0); 
            }
        }, 0, 0);

    # setting up altTrigg timer
	altTrigger = maketimer(1, func () {
        if (getprop("position/altitude-agl-ft") > 20)
            setprop(PROP_PATH ~ "altTrig", 1); 
    }); 
	altTrigger.start();
    
    # setting up landed listener
	var landed = setlistener(PROP_PATH ~ "landed", func {
        if(getprop(PROP_PATH ~ "landed") and getprop(PROP_PATH ~ "altTrig")) { 
            setprop(PROP_PATH ~ "altTrig", 0);
            send_landing_message(getprop("accelerations/pilot-gdamped"), getprop("instrumentation/vertical-speed-indicator/indicated-speed-fpm"), getprop("instrumentation/vertical-speed-indicator/indicated-speed-mps"), geo.aircraft_position());
        } 
    }); 
}

var send_landing_message = func (g, fpm, mps, pos){
	f = fpm * -1; # get fpm with no (-)
	var absdist = pos.distance_to(tgt_pos);
    
    var crs = pos.course_to(tgt_pos);
    crs -= rwy.heading;

    
    var overshoot = -absdist * math.cos(D2R*crs); 
    var offcenter = absdist * math.sin(D2R*crs);
    
    var msg = "Landed! Fpm: " ~ sprintf("%.3f", fpm) ~ "; Mps: " ~ sprintf("%.3f", mps) ~ "; G-Force: " ~ sprintf("%.1f", g) ~ "; Distance to target: " ~ sprintf("%.1f", overshoot) ~ "; Distance from Centerline: " ~ sprintf("%.1f", offcenter);

    window.write(msg);
	print("Last Land: " ~ msg); 
	# if (SHARE_RATE_MP) send_mp_msg(msg); # send mp message if allowed
    
}

var unload = func(addon) {
    # This function is for addon development only. It is called on addon 
    # reload. The addons system will replace setlistener() and maketimer() to
    # track this resources automatically for you.
    #
    # Listeners created with setlistener() will be removed automatically for you.
    # Timers created with maketimer() will have their stop() method called 
    # automatically for you. You should NOT use settimer anymore, see wiki at
    # http://wiki.flightgear.org/Nasal_library#maketimer.28.29
    #
    # Other resources should be freed by adding the corresponding code here,
    # e.g. myCanvas.del();
}

var main = func(addon) {
  logprint(LOG_INFO, "Landing-Challenge addon initialized from path ", addon.basePath);
  
  tgt_pos = setup_runway(addon);
  init_landing_rate_timer();
  
  
}
