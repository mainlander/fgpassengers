var SEAT_BELT_SWITCH_PROP = "/fgpassengers/flight/belt-sign";

var belt_settings = {
    prop: "/fgpassengers/flight/belt-sign",
    use_bool: 1,
    on_value: 1,
    off_value: 0,
    status: 0,
    update: func {
        var prop = getprop(belt_settings.prop);
        if (me.use_bool == 1) {
            print("belt use bool and current " ~ prop);
            me.status = prop ? 1 : 0;
        }
        else {
            print("belt not use bool");
            if (prop == me.on_value) {
                print("belt sign on");
                me.status = 1;
            }
            else if (prop == me.off_value) {
                print("belt sign off");
                me.status = 0;
            }
        }
    },
};

var AircraftStage = {
    INITIAL: 1, TAXI_DEPART: 2, TAKEOFF: 3, CLIMB: 4, CRUISE: 5, 
    DESCENT: 6, APPROACH: 7, TOUCHDOWN: 8, TAXI_ARRIVAL: 9, PARK: 10,
};

var moduleInit = func {
    print("[fgpassengers] module init");

    readSettings();

    setprop("/fgpassengers/start", 0);

    var FG_ROOT = getprop("/sim/fg-root");

    var beltSwitchPerAircraft = {
        '707': '/b707/call/seat-belts',
        'A330-303': '/controls/switches/seatbelt-sign',
        'A330-323': '/controls/switches/seatbelt-sign',
        'A330-343': '/controls/switches/seatbelt-sign',
    };

    var aircraft = getprop("/sim/aircraft");

    print("[fgpassengers] start loading aircraft config xml");
    var aircraft_setting = io.read_properties(FG_ROOT ~ "/FGPassengers/Aircraft/" ~ aircraft ~ ".xml", "/fgpassengers");
    print("[fgpassengers] after loading aircraft config xml");
    if (aircraft_setting == nil) {
        print("[fgpassengers] No aircraft config xml");
    }

    if (getprop("/fgpassengers/belt/prop") != nil) {
        belt_settings.prop = getprop("/fgpassengers/belt/prop");
    }
    if (getprop("/fgpassengers/belt/use-bool") != nil) {
        belt_settings.use_bool = getprop("/fgpassengers/belt/use-bool");
    }
    if (getprop("/fgpassengers/belt/on-value") != nil) {
        belt_settings.on_value = getprop("/fgpassengers/belt/on-value");
    }
    if (getprop("/fgpassengers/belt/off-value") != nil) {
        belt_settings.off_value = getprop("/fgpassengers/belt/off-value");
    }

    setLoadProps();
}

var saveSettings = func {
    var FG_HOME = getprop("/sim/fg-home");
    var save_data = io.write_properties(FG_HOME ~ "/Export/fgpassengers-settings.xml", "/fgpassengers/settings");
    return (save_data != nil) ? 1 : 0;
}

var readSettings = func {
    var FG_HOME = getprop("/sim/fg-home");
    var settings_data = io.read_properties(FG_HOME ~ "/Export/fgpassengers-settings.xml", "/fgpassengers/settings");
    if (settings_data == nil) {
        print("Not FGPassengers settings");
        setprop("/fgpassengers/settings/company/name", "Default Company");
        setprop("/fgpassengers/settings/company/reputation", 10);
        setprop("/fgpassengers/settings/company/fund", 100000);
        setprop("/fgpassengers/settings/pilot/name", "Default Pilot");
        setprop("/fgpassengers/settings/pilot/level", 1);
        setprop("/fgpassengers/settings/pilot/score", 0);
        if (saveSettings()) {
            print("Save Settings success");
        }
        else {
            print("Save Settings failed");
        }
    }
    else {
        print("Has FGPassengers settings");
    }
}


var PassengerInfoDlg = {
    dlg: nil,
    canvas_root: nil,
    belt_status_text: nil,
    onboard_text: nil,
    belt_text: nil,
    satisfy_text: nil,
    fear_text: nil,
    new: func {
        mydlg = canvas.Window.new([270, 85]);
        var my_canvas = mydlg.createCanvas()
                             .setColorBackground(0,0,1,0.7);

        my_canvas.addEventListener("drag", func(e) {
            mydlg.move(e.deltaX, e.deltaY);
        });

        var root = my_canvas.createGroup();

        var belt_status_text =
          root.createChild("text")
              .setText(sprintf("seat belt sign is %s", "OFF"))
              .setAlignment("left-center")
              .setFontSize(12)
              .setTranslation(10, 10)
              .set("max-width", 380)
              .setColor(1,1,1);

        var onboard_text =
          root.createChild("text")
              .setText(sprintf("%d passengers aboard", 0))
              .setAlignment("left-center")
              .setFontSize(12)
              .setTranslation(10, 25)
              .set("max-width", 380)
              .setColor(1,1,1);
     
        var belt_text =
          root.createChild("text")
              .setText(sprintf("%d passengers have their belt", 0))
              .setAlignment("left-center")
              .setFontSize(12)
              .setTranslation(10, 40)
              .set("max-width", 380)
              .setColor(1,1,1);

        var satisfication_text =
          root.createChild("text")
              .setText(sprintf("passengers satisfication %d%%", 0))
              .setAlignment("left-center")
              .setFontSize(12)
              .setTranslation(10, 55)
              .set("max-width", 380)
              .setColor(1,1,1);

        var fear_text =
          root.createChild("text")
              .setText(sprintf("passengers fear %d%%", 0))
              .setAlignment("left-center")
              .setFontSize(12)
              .setTranslation(10, 70)
              .set("max-width", 380)
              .setColor(1,1,1);
        return { parents: [PassengerInfoDlg], dlg:mydlg, belt_status_text:belt_status_text, onboard_text:onboard_text, belt_text:belt_text, satisfy_text:satisfication_text, fear_text:fear_text }
    },
    delete: func {
        me.dlg.del();
    },
    update: func {
        #var beltSwitch = getprop(belt_settings.prop);
        me.belt_status_text.setText(sprintf("belt sign is %s", belt_settings.status ? "ON" : "OFF"));
        var aboard = getprop("/fgpassengers/passengers/aboard");
        var total = getprop("/fgpassengers/passengers/total");
        me.onboard_text.setText(sprintf("%d passengers aboard", aboard));
        var belted = getprop("/fgpassengers/passengers/belted");
        me.belt_text.setText(sprintf("%d passengers have their belt", belted));
        var satisfy = getprop("/fgpassengers/passengers/satisfication");
        me.satisfy_text.setText(sprintf("passengers satisfication %d%%", satisfy));
        var fear = getprop("/fgpassengers/passengers/fear");
        me.fear_text.setText(sprintf("passengers fear %d%%", fear));
    },
};

var infoDlg = nil;

var showPassengerInfo = func {
    if (infoDlg == nil) {
        infoDlg = PassengerInfoDlg.new();
        infoDlg.update();
    }
}

var hidePassengerInfo = func {
    if (infoDlg != nil) {
        infoDlg.delete();
        infoDlg = nil;
    }
}

var togglePassengerInfo = func {
    if (infoDlg == nil) {
        showPassengerInfo();
    }
    else {
        hidePassengerInfo();
    }
}

var currentStep = 0;
var startBoarding = 0;
var beltSignOn = 0;
var beltSwitchListenerId = nil;

var boarding = func {
    var current = getprop("/fgpassengers/passengers/aboard");
    var total = getprop("/fgpassengers/passengers/total");
    var belted = getprop("/fgpassengers/passengers/belted");
    if (rand() < (0.9 - (current - belted) * 0.01)) {  # simulate blocking
        var delta = int(rand() * 5);
        var amount = current + delta;
        if (amount >= total) {
            setprop("fgpassengers/passengers/aboard", total);
            setprop("fgpassengers/passengers/allaboard", 1);
            startBoarding = 0;
            setprop("/sim/messages/copilot", "Passengers are all aboard.");
        }
        else {
            setprop("fgpassengers/passengers/aboard", amount);
        }
    } 
}

var seatbelt = func {
    if (beltSignOn) {
        var current = getprop("/fgpassengers/passengers/aboard");
        var belted = getprop("/fgpassengers/passengers/belted");
        if (belted < current) {
            var delta = int(rand() * 10);
            var amount = belted + delta;
            if (amount >= current) {
                setprop("fgpassengers/passengers/belted", current);
            }
            else {
                setprop("fgpassengers/passengers/belted", amount);
            }
        }
    }
    else {
        var current = getprop("/fgpassengers/passengers/aboard");
        var belted = getprop("/fgpassengers/passengers/belted");

        if (belted > (current / 2)) {
            var delta = int(rand() * 5);
            var amount = belted - delta;
            if (amount > 0)  {
                setprop("fgpassengers/passengers/belted", amount);
            }
        }
        else {
            var delta = int(rand() * 2);
            var amount = belted + delta;
            if (amount < current)  {
                setprop("fgpassengers/passengers/belted", amount);
            }
        }
    }
}

var checkVne = func {
    var pilot_g = getprop("/accelerations/pilot-gdamped");
    if (pilot_g > 1.7 or pilot_g < -1.0) {
        setprop("/fgpassengers/emergency/exceed-g", 1);
        setprop("/fgpassengers/passengers/fear", 100);
    }
    else {
        setprop("/fgpassengers/emergency/exceed-g", 0);
    }
    
    var pos_g_limit = getprop("/limits/max-positive-g") or getprop("/fgpassengers/aircraft/limits/max-positive-g");
    var neg_g_limit = getprop("/limits/max-negative-g") or getprop("/fgpassengers/aircraft/limits/max-negative-g");
    
    if ((pos_g_limit != nil) and (neg_g_limit != nil)) {
        if (pilot_g > pos_g_limit or pilot_g < neg_g_limit) {
            setprop("/fgpassengers/report/exceed-g-demaged", 1);
        }
    }

    var airspeed = getprop("velocities/airspeed-kt");
    var vne = getprop("limits/vne") or getprop("/fgpassengers/aircraft/limits/vne");

    if ((airspeed != nil) and (vne != nil) and (airspeed > vne)) {
        setprop("/fgpassengers/report/exceed-vne", 1);
        setprop("/fgpassengers/passengers/fear", 100);
    }
}

var checkGear = func(n) {
    if (!n.getValue())
        return;

    var airspeed = getprop("velocities/airspeed-kt");
    var max_gear = getprop("limits/max-gear-extension-speed") or getprop("/fgpassengers/aircraft/limits/max-gear-extension-speed");

    if ((airspeed != nil) and (max_gear != nil) and (airspeed > max_gear)) {
        setprop("/fgpassengers/report/exceed-max-gear", 1);
        failures.failProp("/controls/gear/gear-down");
        setprop("/fgpassengers/sound/fail-gear-flap", 1);
        settimer(func { setprop("/fgpassengers/soud/fail-gear-flap", 0); }, 5);
    }
}

var checkFlaps = func(n) {
    var flapsetting = n.getValue();
    if (flapsetting == 0)
        return;

    var airspeed = getprop("velocities/airspeed-kt");

    var limits = props.globals.getNode("limits");
    if (limits == nil and getprop("/fgpassengers/aircraft/has-limit")) {
        limits = props.globals.getNode("/fgpassengers/aircraft/limits");
    }
 
    print("FGPassengers get limit: " ~ (limits != nil));

    if ((limits != nil) and (limits.getChildren("max-flap-extension-speed") != nil)) {
        var children = limits.getChildren("max-flap-extension-speed");
        foreach(var c; children) {
            if ((c.getChild("flaps") != nil) and (c.getChild("speed") != nil)) {
                var flaps = c.getChild("flaps").getValue();
                var speed = c.getChild("speed").getValue();
                print("flaps:" ~ flaps ~ " speed:" ~ speed);

                if ((flaps != nil) and (speed != nil) and (flapsetting >= flaps) and (airspeed > speed)) {
                    setprop("/fgpassengers/report/exceed-flap-speed", 1);
                    failures.failProp("/controls/flight/flaps");
                    setprop("/fgpassengers/sound/fail-gear-flap", 1);
                    settimer(func { setprop("/fgpassengers/soud/fail-gear-flap", 0); }, 5);
                }
            }
        }
    }
}

var checkStage = func {
    var stage = getprop("/fgpassengers/aircraft/stage") or 1;

    if (stage == AircraftStage.INITIAL) {
        var ground_speed = getprop("/velocities/groundspeed-kt");
        if ((ground_speed != nil) and ground_speed > 5) {
            setprop("/fgpassengers/aircraft/stage", AircraftStage.TAXI_DEPART);
            print("Aircraft Stage to Taxi Depart");
        }
    }
    else if (stage == AircraftStage.TAXI_DEPART) {
        var ground_speed = getprop("/velocities/groundspeed-kt");
        if ((ground_speed != nil) and ground_speed > 35) {
            setprop("/fgpassengers/aircraft/stage", AircraftStage.TAKEOFF);
            print("Aircraft Stage to Takeoff");
        }
    }
    else if (stage == AircraftStage.TAKEOFF) {
        var airspeed = getprop("/velocities/airspeed-kt");
        if ((airspeed != nil) and airspeed < 35) {  # Take-off abort
            setprop("/fgpassengers/aircraft/stage", AircraftStage.TAXI_DEPART);
            print("Aircraft Stage back to Taxi Depart");
        }
        else {
            var altitute = getprop("/position/altitude-ft");
            var ground_alt = getprop("/position/ground-elev-ft");
            if ((altitute != nil) and (ground_alt != nil)) {
                if (altitute - ground_alt > 110) {
                    setprop("/fgpassengers/aircraft/stage", AircraftStage.CLIMB);
                    print("Aircraft Stage to Climb");
                }
            }
        }
    }
    else if (stage == AircraftStage.CLIMB) {
        var altitute = getprop("/position/altitude-ft");
        var cruise_alt = getprop("/fgpassengers/flight/cruise-altitute");
        
        if ((altitute != nil) and (cruise_alt != nil)) {
            var delta = altitute - cruise_alt;
            if ((delta > 0 and delta < 200) or (delta < 0 and delta > -200)) {
                setprop("/fgpassengers/aircraft/stage", AircraftStage.CRUISE);
                print("Aircraft Stage to Cruise");
            }
        }
    }
    else if (stage == AircraftStage.CRUISE) {
        var altitute = getprop("/position/altitude-ft");
        var cruise_alt = getprop("/fgpassengers/flight/cruise-altitute");
        
        if ((altitute != nil) and (cruise_alt != nil)) {
            var delta = cruise_alt - altitute;
            if (delta > 2000) {
                setprop("/fgpassengers/aircraft/stage", AircraftStage.DESCENT);
                print("Aircraft Stage to Descent");
            }
        }
    }
    else if (stage == AircraftStage.DESCENT) {
        var altitute = getprop("/position/altitude-ft");
        var ground_alt = getprop("/position/ground-elev-ft");
        if ((altitute != nil) and (ground_alt != nil)) {
            if (altitute - ground_alt < 2500) {
                setprop("/fgpassengers/aircraft/stage", AircraftStage.APPROACH);
                print("Aircraft Stage to APPROACH");
            }
        }
    }
    else if (stage == AircraftStage.APPROACH) {
        var altitute = getprop("/position/altitude-ft");
        var ground_alt = getprop("/position/ground-elev-ft");
        if ((altitute != nil) and (ground_alt != nil)) {
            if (altitute - ground_alt < 50) {
                setprop("/fgpassengers/aircraft/stage", AircraftStage.TOUCHDOWN);
                print("Aircraft Stage to Touch Down");
            }
            else if (altitute - ground_alt > 2500) {
                setprop("/fgpassengers/aircraft/stage", AircraftStage.DESCENT);
                print("Aircraft Stage back to Descent");
            }
        }
    }
    else if (stage == AircraftStage.TOUCHDOWN) {
        var ground_speed = getprop("/velocities/groundspeed-kt");
        if ((ground_speed != nil) and ground_speed < 45) {
            setprop("/fgpassengers/aircraft/stage", AircraftStage.TAXI_ARRIVAL);
            print("Aircraft Stage to Taxi Arrival");
        }
        else {
            var altitute = getprop("/position/altitude-ft");
            var ground_alt = getprop("/position/ground-elev-ft");
            if ((altitute != nil) and (ground_alt != nil)) {
                if (altitute - ground_alt > 210) {  # Go around
                    setprop("/fgpassengers/aircraft/stage", AircraftStage.APPROACH);
                    print("Aircraft Stage back to Approach");
                }
            }
        }
    }
    else if (stage == AircraftStage.TAXI_ARRIVAL) {
        var ground_speed = getprop("/velocities/groundspeed-kt");
        if ((ground_speed != nil) and ground_speed < 2) {
            setprop("/fgpassengers/aircraft/stage", AircraftStage.PARK);
            print("Aircraft Stage to Park");
        }
    }
    else if (stage == AircraftStage.PARK) {
    }
}

var boardingLoop = func {
    if (startBoarding) {
        boarding();
    }
    else {
        boardingTimer.stop();
    }
}


var mainLoop = func {
    seatbelt();
    checkVne();
    checkStage();

    if (infoDlg != nil) {
        infoDlg.update();
    }
}

var resetValues = func {
    setprop("/fgpassengers/passengers/aboard", 0);
    setprop("/fgpassengers/passengers/belted", 0);
    setprop("/fgpassengers/passengers/satisfication", 60);
    setprop("/fgpassengers/passengers/fear", 30);
    setprop("/fgpassengers/aircraft/stage", AircraftStage.INITIAL);
    setprop("/fgpassengers/flight/belt-sign", 0);
    belt_settings.update();
    beltSignOn = belt_settings.status;
    startBoarding = 1;
    currentStep = 0;
}

var beltSwitchSlot = func {
    print("[fgpassengers] belt slot!");
    belt_settings.update();
    beltSignOn = belt_settings.status;
    print("[fgpassengers] belt sign:" ~ beltSignOn);
    if (infoDlg != nil) {
        print("[fgpassengers] info update!");
        infoDlg.update();
    }
}

var gearWoW = func (n) {
    print("gear WOW");
    var wow = n.getValue() or 0.0;
    var dn_speed = getprop("/velocities/speed-down-fps");
    if (wow and dn_speed and dn_speed > 20) {
        print("Hard landing!");
        setprop("/fgpassengers/report/hard-landing", 1);
    }
}

var crashedSlot = func (n) {
    print("crashedSlot");
    var crashed = n.getValue() or 0;
    print("crashed:" ~ crashed);
    if (crashed) {
        print("Aircraft Crashed!");
        setprop("/fgpassengers/report/crashed", 1);
    }
}

var beginSettings = func {
    showFGPassengersStartDialog();
}

var mainloopTimer = maketimer(2.0, mainLoop);
var boardingTimer = maketimer(5.0, boardingLoop);

var start = func {
    print("[fgpassengers] start"); 
    setprop("/fgpassengers/start", 1);
    #var data = io.read_properties("/Applications/FlightGear.app/Contents/Resources/data/Sounds/fgpassengers/fgpassengers-sound.xml", "/sim/sound");
    resetValues();
    showPassengerInfo();
    print("[fgpassengers] set seat-belts listener " ~ belt_settings.prop); 
    beltSwitchListenerId = setlistener(belt_settings.prop, beltSwitchSlot);
    print("[fgpassengers] set seat-belts listener id " ~ beltSwitchListenerId); 
    belt_settings.update();
    mainloopTimer.start();
    if (startBoarding) {
        boardingTimer.start();
    }
    setprop("/sim/messages/copilot", "Start boarding");
    settimer(func { setprop("/fgpassengers/sound/crew/welcomeonboard", 1); }, 40);
    # Menu items enable
    gui.menuEnable("fgpassengers-end-flight", 1);
    if (belt_settings.prop == SEAT_BELT_SWITCH_PROP) {
        gui.menuEnable("fgpassengers-toggle-belt-sign", 1);
    }
    gui.menuEnable("fgpassengers-info", 1);
    gui.menuEnable("fgpassengers-start-a-flight", 0);

    # Set listener for checking flap and gear speed
    setlistener("controls/flight/flaps", checkFlaps);
    setlistener("controls/gear/gear-down", checkGear);
    var gear_amount = getprop("/fgpassengers/aircraft/gear-amount") or 3;
    for (var i = 0; i < gear_amount; i = i + 1) {
        setlistener("/gear/gear[" ~ i ~ "]/wow", gearWoW, 0, 0);
    }
    var crashed_prop = getprop("/fgpassengers/aircraft/crashed") or "/sim/crashed";
    if (crashed_prop != nil) {
        print("has crashed_prop");
        setlistener(crashed_prop, crashedSlot, 0, 0);
    }
}

var calculatePayload = func {
    var payload_base = props.globals.getNode("/fgpassengers/aircraft/payload");
    if (payload_base != nil)
        var wgts = payload_base.getChildren("item");
    else
        var wgts = [];

    var weights = {};
    var total_pax = 0;
    var total_lbs = 0.0;

    for (var i = 0; i < size(wgts); i += 1) {
        var w = wgts[i];
        var value = w.getNode("value", 1).getValue() or 0.0;
        var unit = w.getNode("unit", 1).getValue() or "lbs";
        var type = w.getNode("type", 1).getValue() or "lbs";
        var wprop = w.getNode("property", 1).getValue();

        var real_value = value;
        if (unit == 'pax') {
            real_value = int(value) * 180.0;  # One passeger 180 pounds
        }
        if (type == "pax") {
            total_pax += int(value);
        }

        if (wprop != nil) {
            if (contains(weights, wprop)) {
                var orgval = weights[wprop];
                weights[wprop] = orgval + real_value;
            }
            else {
                weights[wprop] = real_value;
            }
        }
        total_lbs += real_value;
    }

    foreach (wprop; keys(weights)) {
        var value = weights[wprop];
        print("set prop "~ wprop ~ " with weight " ~ value);
        setprop(wprop ~ "/weight-lb", value);
    }

    setprop("/fgpassengers/payload/total-pax", total_pax);
    setprop("/fgpassengers/passengers/total", total_pax);
    setprop("/fgpassengers/payload/total-lbs", total_lbs);
}

var setLoadProps = func {
    var payload_base = props.globals.getNode("/fgpassengers/aircraft/payload");
    if (payload_base != nil)
        var wgts = payload_base.getChildren("item");
    else
        var wgts = [];

    for (var i = 0; i < size(wgts); i += 1) {
        var w = wgts[i];
        var wprop = "/fgpassengers/aircraft/payload/item[" ~ i ~ "]";
        setlistener(wprop ~ "/value", calculatePayload);
    }
}

_setlistener("/nasal/fgpassengers/loaded", moduleInit);
