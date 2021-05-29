var challenge = {};

var landingChallenge = {
    # helpers
    PROP_PATH: "/addons/by-id/org.flightgear.addons.landing-challenge/addon-devel/",
    
    # bookkeeping:
    instances: [],
    
    # constructor
    new: func(path) {
        var obj = { parents: [landingChallenge],
            
            # bookkeeping
            listeners: [],
            cleanup: func() {
                if (me.timer != nil and me.timer.stop != nil)
                    me.timer.stop();
                foreach(var id; obj.listeners) {
                    print("Removing LandingChallenge listener "~id);
                    removelistener(id);
                }
                me.listeners = [];
            },
            
            # members
            #model references
            cones: [],
            chalkMarks: nil,
            
            gear_props: [],
            landedProp: nil,
            altTrigProp: nil,
            
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
            
            # setting things up...
            # reference to addon base path
            addonBasePath: path,
            
            # props for landing and altitude trigger
            landedProp: props.globals.getNode(me.PROP_PATH~"landed"),
            altTrigProp: props.globals.getNode(me.PROP_PATH~"altTrig"),
            
            #the message window for in-game display
            window: screen.window.new(10, 10, 3, 10), # create new window object. 750, 10 : Lower Right
            
        };
        # some more bookkeeping
        append(landingChallenge.instances, obj);
        
        obj.landedProp.initNode(0);
        obj.altTrigProp.initNode(0);
        
        obj.window.bg = [0,0,0,.5]; # black alpha .5 background
            
        # behave like a real constructor and return yourself
        return obj;
    },
    
    # destructor
    del: func() {
        foreach (var i; landingChallenge.instances) {
            i.cleanup();
        }
        landingChallenge.instances = [];
    },
    
    # interface
    get_tgt_pos: func() {
        return tgt_pos;
    },
    
    setupRunway: func() {
        var aptName = getprop(me.PROP_PATH ~ "airport");
        var rwyName = getprop(me.PROP_PATH ~ "runway");
        me.tgt_dst = getprop(me.PROP_PATH ~ "target-dist-m");

        # get information about selected airport
        me.tgt_apt = airportinfo(aptName);
        
        # find selected runway
        foreach (var r; keys(me.tgt_apt.runways)) {
            var curr = me.tgt_apt.runways[r];
            
            if (me.tgt_apt.runways[r].id == rwyName) {
                me.tgt_rwy = curr;
                break;
            }
        }
        
        # the landing target position
        me.tgt_pos.set_latlon(me.tgt_rwy.lat, me.tgt_rwy.lon);
        
        #offset the target distance from threshold
        me.tgt_pos.apply_course_distance(me.tgt_rwy.heading, me.tgt_dst);
        
        me.tgt_pos.set_alt(geo.elevation(me.tgt_pos.lat(), me.tgt_pos.lon()));
        
        # place the chalk markings for the landing area on the runway
        me.chalkMarks = geo.put_model(me.addonBasePath~"/Models/markings-ga.xml", me.tgt_pos, me.tgt_rwy.heading);
        print("tgt elevation: " ~ sprintf("%.3f", geo.elevation(me.tgt_pos.lat(), me.tgt_pos.lon())));
        
        var conepos = geo.Coord.new(me.tgt_pos);
        var left = 0;
        var right = 0;
        
        if(me.tgt_rwy.heading - 90 < 0) {
            left = me.tgt_rwy.heading - 90 + 360;
        } else {
            left = me.tgt_rwy.heading - 90;
        }    
        if(me.tgt_rwy.heading + 90 > 360) {
            right = me.tgt_rwy.heading + 90 - 360;
        } else {
            right = me.tgt_rwy.heading + 90;
        }
        
        #place the cones for tdz-area
        for(var i=1; i<4; i=i+1) {
            conepos.set(me.tgt_pos);
            conepos.apply_course_distance(left, 12.5 + 0.5*i);
            append(me.cones, geo.put_model(me.addonBasePath~"/Models/cone.xml", conepos));
            conepos.set(me.tgt_pos);
            conepos.apply_course_distance(right, 12.5 + 0.5*i);
            append(me.cones, geo.put_model(me.addonBasePath~"/Models/cone.xml", conepos));
            
        }
	},
	
	#return tgt_pos{
    #},
    
    setupAirplane: func() {
        #hard-coded, for now
        me.gear_props = ["gear/gear[0]/wow", "gear/gear[1]/wow", "gear/gear[2]/wow"];
    },
    
    removeModels: func() {
        me.chalkMarks.remove;
        foreach (var cone; me.cones) {
            cone.remove;
        }
    },
    
    setupLandingListeners: func() {
        # set gear props listeners
        forindex(var i; me.gear_props) 
            setlistener(me.gear_props[i], func(n) {
                if(n.getValue() and !me.landedProp.getBoolValue()) {
                    me.landedProp.setValue(1);
                } else {
                     me.landedProp.setValue(0);
                }
            }, 0, 0);
        
        # setting up altTrigg timer
        altTrigger = maketimer(1, func () {
            if (getprop("position/altitude-agl-ft") > 20)
                me.altTrigProp.setValue(1);
        }); 
        altTrigger.start();
        
        # setting up landed listener
        var landed = setlistener(me.landedProp, func {
            if(me.landedProp.getBoolValue() and me.altTrigProp.getBoolValue()) { 
                me.altTrigProp.setValue(0);
                
                me.gforce = getprop("accelerations/pilot-gdamped");
                me.fpm = getprop("instrumentation/vertical-speed-indicator/indicated-speed-fpm");
                me.landingPos = geo.aircraft_position();
                
                me.printLandingMessage();
            } 
        }); 
    },
    
    printLandingMessage: func() {
        var f = me.fpm * -1; # get fpm with no (-)
        var absdist = me.landingPos.distance_to(me.tgt_pos);
        
        var crs = me.landingPos.course_to(me.tgt_pos);
        crs -= me.tgt_rwy.heading;
        
        var overshoot = -absdist * math.cos(D2R*crs); 
        var offcenter = absdist * math.sin(D2R*crs);
        
        var msg = "Landed! Fpm: " ~ sprintf("%.3f", f) ~ "; G-Force: " ~ sprintf("%.1f", me.gforce) ~ "; Distance to target: " ~ sprintf("%.1f", overshoot) ~ "; Distance from Centerline: " ~ sprintf("%.1f", offcenter);
        
        #me.window.write(msg);
        print("Last Landing: " ~ msg); 
        # if (SHARE_RATE_MP) send_mp_msg(msg); # send mp message if allowed
    },
}; # landingChallenge Class

###### dialog function calls #####
challenge.setupChallenge = func() {
    var ch = landingChallenge.new(addonBasePath);    
    ch.setupRunway();
    ch.setupAirplane();
    ch.setupLandingListeners();
}
