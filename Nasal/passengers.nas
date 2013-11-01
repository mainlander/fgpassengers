var SEAT_BELT_SWITCH_PROP = "/fgpassengers/flight/belt-sign";

var moduleInit = func {

    setprop("/fgpassengers/start", 0);

    var FG_ROOT = getprop("/sim/fg-root");

    var beltSwitchPerAircraft = {
        '707': '/b707/call/seat-belts',
        'A330-303': '/controls/switches/seatbelt-sign',
        'A330-323': '/controls/switches/seatbelt-sign',
        'A330-343': '/controls/switches/seatbelt-sign',
    };

    var aircraft = getprop("/sim/aircraft");

    var aircraft_setting = io.read_properties(FG_ROOT ~ "/FGPassengers/Aircraft/" ~ aircraft ~ ".xml", "/fgpassengers");

    if (beltSwitchPerAircraft[aircraft]) {
        SEAT_BELT_SWITCH_PROP = beltSwitchPerAircraft[aircraft];
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
        var beltSwitch = getprop(SEAT_BELT_SWITCH_PROP);
        me.belt_status_text.setText(sprintf("belt sign is %s", beltSwitch ? "ON" : "OFF"));
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

var mainLoop = func {
    if (startBoarding) {
        boarding();
    }

    seatbelt();

    if (infoDlg != nil) {
        infoDlg.update();
    }
}

var resetValues = func {
    setprop("/fgpassengers/passengers/aboard", 0);
    setprop("/fgpassengers/passengers/belted", 0);
    setprop("/fgpassengers/passengers/satisfication", 60);
    setprop("/fgpassengers/passengers/fear", 30);
    setprop("/fgpassengers/sounds/scream", 1);
    beltSignOn = getprop(SEAT_BELT_SWITCH_PROP) ? 1 : 0;
    startBoarding = 1;
    currentStep = 0;
}

var beltSwitchSlot = func {
    beltSignOn = getprop(SEAT_BELT_SWITCH_PROP) ? 1 : 0;
    if (infoDlg != nil) {
        infoDlg.update();
    }
}

var mainloopTimer = maketimer(2.0, mainLoop);

var start = func {
    var data = io.read_properties("/Applications/FlightGear.app/Contents/Resources/data/Sounds/fgpassengers/fgpassengers-sound.xml", "/sim/sound");
    resetValues();
    showPassengerInfo();
    beltSwitchListenerId = setlistener(SEAT_BELT_SWITCH_PROP, beltSwitchSlot);
    mainloopTimer.start();
    setprop("/sim/messages/copilot", "Start boarding");
}

_setlistener("/sim/signals/nasal-dir-initialized", moduleInit);
