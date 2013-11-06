var SEAT_BELT_SWITCH_PROP = "/fgpassengers/flight/belt-sign";

var belt_settings = {
    prop: "/fgpassengers/flight/belt-sign",
    use_bool: 1,
    on_value: 1,
    off_value: 0,
    status: 0,
    update: func {
        var prop = getprop(belt_settings.prop);
        if (me.use_bool) {
            me.status = prop ? 1 : 0;
        }
        else {
            if (prop == me.on_value) {
                me.status = 1;
            }
            else if (prop == me.off_value) {
                me.status = 0;
            }
        }
    },
};

var moduleInit = func {
    print("[fgpassengers] module init");

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

    belt_settings.prop = getprop("/fgpassengers/belt/prop") or SEAT_BELT_SWITCH_PROP;
    belt_settings.use_bool = getprop("/fgpassengers/belt/use-bool") or 1;
    belt_settings.on_value = getprop("/fgpassengers/belt/on-value") or 1;
    belt_settings.off_value = getprop("/fgpassengers/belt/off-value") or 0;
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
        setprop("/sim/failure-manager/controls/gear/gear-down/mcbf", 1);
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
                    setprop("/sim/failure-manager/controls/flight/flaps/mcbf", 1);
                    setprop("/sim/failure-manager/controls/flight/flaps/serviable", 0);
                    setprop("/fgpassengers/sound/fail-gear-flap", 1);
                    settimer(func { setprop("/fgpassengers/soud/fail-gear-flap", 0); }, 5);
                }
            }
        }
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

    if (infoDlg != nil) {
        infoDlg.update();
    }
}

var resetValues = func {
    setprop("/fgpassengers/passengers/aboard", 0);
    setprop("/fgpassengers/passengers/belted", 0);
    setprop("/fgpassengers/passengers/satisfication", 60);
    setprop("/fgpassengers/passengers/fear", 30);
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

var mainloopTimer = maketimer(2.0, mainLoop);
var boardingTimer = maketimer(5.0, boardingLoop);

var start = func {
    print("[fgpassengers] start"); 
    #var data = io.read_properties("/Applications/FlightGear.app/Contents/Resources/data/Sounds/fgpassengers/fgpassengers-sound.xml", "/sim/sound");
    resetValues();
    showPassengerInfo();
    #showAircraftPayloadDialog();
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
    # Set listener for checking flap and gear speed
    setlistener("controls/flight/flaps", checkFlaps);
    setlistener("controls/gear/gear-down", checkGear);
}



_setlistener("/nasal/fgpassengers/loaded", moduleInit);
