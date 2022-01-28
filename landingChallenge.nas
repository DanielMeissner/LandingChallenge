#This file is part of FlightGear.
#
#FlightGear is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
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
# Copyright (C) 2021 D. Meissner (danielHL.83@googlemail.com) 
#
# Based on landing-rate addon by RenanMsV (https://github.com/RenanMsV/landing_rate)
#

var challenge = {};

var LandingChallenge = {
	# helpers
	PROP_PATH: "/addons/by-id/org.flightgear.addons.landing-challenge/addon-devel/",
	
	# constructor
	new: func(path) {
		var obj = {
			parents: [LandingChallenge],
			
			# bookkeeping
			listeners: [],
			cleanup: func() {
				foreach(var id; obj.listeners) {
					print("Removing LandingChallenge listener " ~ id);
					removelistener(id);
				}
				me.listeners = [];
			},
			
			# members
			# model references
			cones: [],
			chalkMarks: nil,
			
			# store landing message for later use
			msg: "You didn't land yet !",
			
			gear_props: [],
			landedProp: nil,
			
			# the target position geo.coords object
			tgt_pos: geo.Coord.new(),
			
			# the target, a bit more abstract. apt and rwy as objects
			tgt_apt: nil,
			tgt_rwy: nil,
			# the target distance from threshold in meters
			tgt_dist: nil,
			
			# landing performance data:
			gforce: 0,
			fpm: 0,
			landingPos: nil,
			bankAngle: 0,
			slipAngle: 0,
			overshoot: 0,
			offcenter: 0,
			
			# setting things up...
			# reference to addon base path
			addonBasePath: path,
			
			# props for landing and altitude trigger
			landedProp: props.globals.getNode(me.PROP_PATH ~ "landed"),
			
			# the message window for in-game display
			window: screen.window.new(10, 10, 3, 10), # create new window object. 750, 10 : Lower Right
			
		};
		obj.landedProp.initNode(0);
		
		obj.window.bg = [0, 0, 0, 0.5]; # black alpha .5 background
		obj.window.fg = [1, 1, 1, 1];
			
		# behave like a real constructor and return yourself
		return obj;
	},
	
	# destructor
	del: func() {
		logprint(LOG_ALERT, "Deleting landing challenges");
		me.removeModels();
		me.cleanup();
	},
	
	# interface
	
	setupRunway: func() {
		# only place the models if GA dompetition mode is selected
		if (getprop(me.PROP_PATH ~ "modes/mode-ga-competition")) {
			var aptName = getprop(me.PROP_PATH ~ "airport");
			var rwyName = getprop(me.PROP_PATH ~ "runway");
			me.tgt_dst = getprop(me.PROP_PATH ~ "target-dist-m");
			
			# TODO: determine pitch at runtime. Also we shouldn't need an elevation offset if we applly the correct pitch.
			var markingsElevationOffset = getprop(me.PROP_PATH ~ "chalkmarkings-offset-m");
			var markingsPitch = getprop(me.PROP_PATH ~ "chalkmarkings-pitch-deg");
			
			var placeCones = getprop(me.PROP_PATH ~ "render-cones");
			# TODO: create / find an obstacle model and place it in the scenery
			var placeObstacle = getprop(me.PROP_PATH ~ "render-obstacle");
			var placeChalkMarkings = getprop(me.PROP_PATH ~ "render-chalkmarkings");
			
			# If aptName contains a parenthese (thus more than the ICAO), get everything between the last pair of parentheses (the ICAO).
			if (find("(", aptName) > -1) {
				aptName = split("(", aptName)[-1];
				aptName = split(")", aptName)[0];
			}

			# Get information about the selected airport
			me.tgt_apt = airportinfo(aptName);
			
			if (me.tgt_apt != nil) {
				# Find selected runway
				foreach (var r; keys(me.tgt_apt.runways)) {
					var curr = me.tgt_apt.runways[r];
					
					if (me.tgt_apt.runways[r].id == rwyName) {
						me.tgt_rwy = curr;
						break;
					}
				}
			} else {
				logprint(LOG_ALERT, "Getting airport information for airport '", aptName, "' failed. Maybe the airport name is malformed ?")
			}
			
			# The landing target position
			me.tgt_pos.set_latlon(me.tgt_rwy.lat, me.tgt_rwy.lon);
			
			# Offset the target distance from threshold
			me.tgt_pos.apply_course_distance(me.tgt_rwy.heading, me.tgt_dst);
			
			if (placeChalkMarkings) {
				# If the user enabled the chalk markings, add the elevation offset to the terrain altitude
				me.tgt_pos.set_alt(geo.elevation(me.tgt_pos.lat(), me.tgt_pos.lon()) + num(markingsElevationOffset));
				
				# Place the chalk markings for the landing area on the runway
				me.chalkMarks = geo.put_model(me.addonBasePath~"/Models/markings-ga.xml", me.tgt_pos, me.tgt_rwy.heading, markingsPitch);
				logprint(LOG_INFO, "Target elevation: " ~ sprintf("%.3f", geo.elevation(me.tgt_pos.lat(), me.tgt_pos.lon())));
			} else {
				me.tgt_pos.set_alt(geo.elevation(me.tgt_pos.lat(), me.tgt_pos.lon()));
			}
			
			if (placeCones) {
				# If the user enabled the TDZ cones, place them on the runway.
				var conepos = geo.Coord.new(me.tgt_pos);
				var left = 0;
				var right = 0;
				
				if (me.tgt_rwy.heading - 90 < 0) {
					left = me.tgt_rwy.heading - 90 + 360;
				} else {
					left = me.tgt_rwy.heading - 90;
				}
					
				if (me.tgt_rwy.heading + 90 > 360) {
					right = me.tgt_rwy.heading + 90 - 360;
				} else {
					right = me.tgt_rwy.heading + 90;
				}
				
				for(var i = 1; i < 4; i = i + 1) {
					conepos.set(me.tgt_pos);
					conepos.apply_course_distance(left, 12.5 + 0.5 * i);
					append(me.cones, geo.put_model(me.addonBasePath~"/Models/cone.xml", conepos));
					conepos.set(me.tgt_pos);
					conepos.apply_course_distance(right, 12.5 + 0.5 * i);
					append(me.cones, geo.put_model(me.addonBasePath~"/Models/cone.xml", conepos));			
				}
			}
		}
	},
	
	setupAirplane: func() {
		# TODO: Determine the gear nodes at runtime
		me.gear_props = ["gear/gear[0]/wow", "gear/gear[1]/wow", "gear/gear[2]/wow"];
	},
	
	removeModels: func() {
		logprint(LOG_ALERT, "Removing models");
		# only try to remove the chalk markings if they were enabled
		if (getprop(me.PROP_PATH ~ "render-chalkmarkings")) {
			me.chalkMarks.removeChildren();
			me.chalkMarks.remove();
		}
		
		foreach (var cone; me.cones) {
			cone.removeChildren();
			cone.remove();
		}
	},
	
	setupLandingListeners: func() {
		# set gear props listeners
		forindex(var i; me.gear_props) {
			setlistener(me.gear_props[i], func(n) {
				if(n.getValue() and !me.landedProp.getBoolValue()) {
					me.landedProp.setValue(1);
				} else {
					 me.landedProp.setValue(0);
				}
			}, 0, 0);
			append(me.listeners, me.gear_props[i])
		}
		
		# setting up landed listener
		var landed = setlistener(me.landedProp, func {
			if(me.landedProp.getBoolValue()) { 
				me.compileLandingData();
				me.printLandingMessage();
			} 
		});
		append(me.listeners, me.landedProp);
	},
	
	compileLandingData: func() {
		me.gForce = getprop("/accelerations/pilot-gdamped");
		me.airspeed = getprop("/velocities/airspeed-kt");
		me.groundspeed = getprop("/velocities/groundspeed-kt");
		me.verticalSpeed = getprop("/velocities/vertical-speed-fps") * 60;
		me.rollAngle = getprop("/orientation/roll-deg");
		me.pitchAngle = getprop("/orientation/pitch-deg");
		
		# XXX: shouldn't we rather show the rotation of the aircraft relative to the runway instead of
		# relative to the direction it's moving ? Or maybe both ?
		me.sideslipAngle = getprop("/orientation/side-slip-deg");
		me.landingPos = geo.aircraft_position();
		
		debug.dump(me.tgt_pos);
		var absdist = me.landingPos.distance_to(me.tgt_pos);
		
		var course = me.landingPos.course_to(me.tgt_pos);
		course -= me.tgt_rwy.heading;
		
		me.overshoot = -absdist * math.cos(D2R * course); 
		me.offcenter = absdist * math.sin(D2R * course);
		
		# output to landing properties
		setprop(me.PROP_PATH ~ "landing-data/g-force", sprintf("%.1f", me.gForce));
		setprop(me.PROP_PATH ~ "landing-data/vertical-speed-fpm", sprintf("%.1f", me.verticalSpeed));
		setprop(me.PROP_PATH ~ "landing-data/overshoot-m", sprintf("%.1f", me.overshoot));
		setprop(me.PROP_PATH ~ "landing-data/offcenter-m", sprintf("%.1f", me.offcenter));
		setprop(me.PROP_PATH ~ "landing-data/roll-deg", sprintf("%.1f", me.rollAngle));
		setprop(me.PROP_PATH ~ "landing-data/pitch-deg", sprintf("%.1f", me.pitchAngle));
		setprop(me.PROP_PATH ~ "landing-data/sideslip-deg", sprintf("%.1f", me.sideslipAngle));
		setprop(me.PROP_PATH ~ "landing-data/airspeed-kt", sprintf("%.1f", me.airspeed));
		setprop(me.PROP_PATH ~ "landing-data/groundspeed-kt", sprintf("%.1f", me.groundspeed));
	},
	
	printLandingMessage: func() {
		me.msg = "Landed! Vertical speed: " ~ sprintf("%.1f", me.verticalSpeed) ~ " FPM; Airspeed: " ~ sprintf("%.1f", me.airspeed) ~ " kts; Groundspeed: " ~ sprintf("%.1f", me.groundspeed) ~ " kts; G-Force: " ~ sprintf("%.1f", me.gForce) ~ ";\nBank angle: " ~ sprintf("%.1f", me.bankAngle) ~ " deg; Pitch angle: " ~ sprintf("%.1f", me.pitchAngle) ~ " deg; Sideslip angle: " ~ sprintf("%.1f", me.sideslipAngle) ~ " deg; Distance to target: " ~ sprintf("%.1f", me.overshoot) ~ " m; Distance from centerline: " ~ sprintf("%.1f", me.offcenter) ~ " m";
		
		logprint(LOG_ALERT, me.msg);
		
		if (getprop(me.PROP_PATH ~ "message")) {
			me.window.write(me.msg);
		}
		
		if (getprop(me.PROP_PATH ~ "message-popup")) {
			fgcommand("show-landing-notification");
		}
		
		if (getprop(me.PROP_PATH ~ "announce-mp")) {
			setprop("/sim/multiplay/chat", me.msg);
		}
	},
}; # LandingChallenge Class

var landingChallenge = nil;

var createLandingChallenge = func {
	landingChallenge = LandingChallenge.new(addonBasePath);	
	landingChallenge.setupRunway();
	landingChallenge.setupAirplane();
	landingChallenge.setupLandingListeners();
}

var removeLandingChallenge = func {
	landingChallenge.del();
	landingChallenge = nil;
}
