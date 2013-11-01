var SEAT_BELT_SWITCH_PROP = "/fgpassengers/flight/belt-sign";

var fdm = getprop("/sim/flight-model");

var dialog = {};

var showAircraftPayloadDialog = func {
    var name = "FGAircarftPayload";
    var title = "Aircraft Payload";

    #
    # General Dialog Structure
    #
    dialog[name] = gui.Widget.new();
    dialog[name].set("name", name);
    dialog[name].set("layout", "vbox");

    var header = dialog[name].addChild("group");
    header.set("layout", "hbox");
    header.addChild("empty").set("stretch", "1");
    header.addChild("text").set("label", title);
    header.addChild("empty").set("stretch", "1");
    var w = header.addChild("button");
    w.set("pref-width", 16);
    w.set("pref-height", 16);
    w.set("legend", "");
    w.set("default", 0);
    w.setBinding("dialog-close");

    dialog[name].addChild("hrule");

    

    if (fdm != "yasim" and fdm != "jsb") {
        var msg = dialog[name].addChild("text");
        msg.set("label", "Not supported for this aircraft");
        var cancel = dialog[name].addChild("button");
        cancel.set("key", "Esc");
        cancel.set("legend", "Cancel");
        cancel.setBinding("dialog-close");
        fgcommand("dialog-new", dialog[name].prop());
        showDialog(name);
        return;
    }

    # FDM dependent settings
    if(fdm == "yasim") {
        var fdmdata = {
            grosswgt : "/yasim/gross-weight-lbs",
            payload  : "/sim",
            cg       : nil,
        };
    } elsif(fdm == "jsb") {
        var fdmdata = {
            grosswgt : "/fdm/jsbsim/inertia/weight-lbs",
            payload  : "/payload",
            cg       : "/fdm/jsbsim/inertia/cg-x-in",
        };
    }

    var flightArea = dialog[name].addChild("group");
    flightArea.set("layout", "table");
    flightArea.set("halign", "center");
    var companyLabel = flightArea.addChild("text");
    companyLabel.set("row", 0);
    companyLabel.set("col", 0);
    companyLabel.set("halign", "right");
    companyLabel.set("label", "Company:");
    var company = flightArea.addChild("input");
    company.set("row", 0);
    company.set("col", 1);
    company.set("halign", "left");
    company.set("label", "0123457890123456789");
    company.set("property", "/fgpassengers/pilot/company");
    company.set("live", 1);

    dialog[name].addChild("hrule");

    var contentArea = dialog[name].addChild("group");
    contentArea.set("layout", "hbox");
    contentArea.set("default-padding", 10);

    dialog[name].addChild("empty");

    var limits = dialog[name].addChild("group");
    limits.set("layout", "table");
    limits.set("halign", "center");
    var row = 0;

    var massLimits = props.globals.getNode("/limits/mass-and-balance");

    var tablerow = func(name, node, format ) {

        var n = isa( node, props.Node ) ? node : massLimits.getNode( node );
        if( n == nil ) return;

        var label = limits.addChild("text");
        label.set("row", row);
        label.set("col", 0);
        label.set("halign", "right");
        label.set("label", name ~ ":");

        var val = limits.addChild("text");
        val.set("row", row);
        val.set("col", 1);
        val.set("halign", "left");
        val.set("label", "0123457890123456789");
        val.set("format", format);
        val.set("property", n.getPath());
        val.set("live", 1);
          
        row += 1;
    }

    var buttonBar = dialog[name].addChild("group");
    buttonBar.set("layout", "hbox");
    buttonBar.set("default-padding", 10);

    var grossWgt = props.globals.getNode(fdmdata.grosswgt);
    if(grossWgt != nil) {
        tablerow("Gross Weight", grossWgt, "%.0f lb");
    }

    if(massLimits != nil ) {
        tablerow("Max. Ramp Weight", "maximum-ramp-mass-lbs", "%.0f lb" );
        tablerow("Max. Takeoff  Weight", "maximum-takeoff-mass-lbs", "%.0f lb" );
        tablerow("Max. Landing  Weight", "maximum-landing-mass-lbs", "%.0f lb" );
        tablerow("Max. Zero Fuel Weight", "maximum-zero-fuel-mass-lbs", "%.0f lb" );
        }

        if( fdmdata.cg != nil ) {
        var n = props.globals.getNode("/limits/mass-and-balance/cg/dimension");
        tablerow("Center of Gravity", fdmdata.cg, "%.1f " ~ (n == nil ? "in" : n.getValue()));
    }

    dialog[name].addChild("hrule");

    var buttonBar = dialog[name].addChild("group");
    buttonBar.set("layout", "hbox");
    buttonBar.set("default-padding", 10);

    var close = buttonBar.addChild("button");
    close.set("legend", "Close");
    close.set("default", "true");
    close.set("key", "Enter");
    close.setBinding("dialog-close");

    # Temporary helper function
    var tcell = func(parent, type, row, col) {
        var cell = parent.addChild(type);
        cell.set("row", row);
        cell.set("col", col);
        return cell;
    }

    #
    # Fill in the content area
    #
    var fuelArea = contentArea.addChild("group");
    fuelArea.set("layout", "vbox");
    fuelArea.addChild("text").set("label", "Fuel Tanks");

    var fuelTable = fuelArea.addChild("group");
    fuelTable.set("layout", "table");

    fuelArea.addChild("empty").set("stretch", 1);

    tcell(fuelTable, "text", 0, 0).set("label", "Tank");
    tcell(fuelTable, "text", 0, 3).set("label", "Pounds");
    tcell(fuelTable, "text", 0, 4).set("label", "Gallons");
    tcell(fuelTable, "text", 0, 5).set("label", "Fraction");

    var tanks = props.globals.getNode("/consumables/fuel").getChildren("tank");
    for(var i=0; i<size(tanks); i+=1) {
        var t = tanks[i];

        var tname = i ~ "";
        var tnode = t.getNode("name");
        if(tnode != nil) { tname = tnode.getValue(); }

        var tankprop = "/consumables/fuel/tank["~i~"]";

        var cap = t.getNode("capacity-gal_us", 0);

        # Hack, to ignore the "ghost" tanks created by the C++ code.
        if(cap == nil ) { continue; }
        cap = cap.getValue();

        # Ignore tanks of capacity 0
        if (cap == 0) { continue; }

        var title = tcell(fuelTable, "text", i+1, 0);
        title.set("label", tname);
        title.set("halign", "right");

        var selected = props.globals.initNode(tankprop ~ "/selected", 1, "BOOL");
        if (selected.getAttribute("writable")) {
            var sel = tcell(fuelTable, "checkbox", i+1, 1);
            sel.set("property", tankprop ~ "/selected");
            sel.set("live", 1);
            sel.setBinding("dialog-apply");
        }

        var slider = tcell(fuelTable, "slider", i+1, 2);
        slider.set("property", tankprop ~ "/level-gal_us");
        slider.set("live", 1);
        slider.set("min", 0);
        slider.set("max", cap);
        slider.setBinding("dialog-apply");

        var lbs = tcell(fuelTable, "text", i+1, 3);
        lbs.set("property", tankprop ~ "/level-lbs");
        lbs.set("label", "0123456");
        lbs.set("format", cap < 1 ? "%.3f" : cap < 10 ? "%.2f" : "%.1f" );
        lbs.set("halign", "right");
        lbs.set("live", 1);

        var gals = tcell(fuelTable, "text", i+1, 4);
        gals.set("property", tankprop ~ "/level-gal_us");
        gals.set("label", "0123456");
        gals.set("format", cap < 1 ? "%.3f" : cap < 10 ? "%.2f" : "%.1f" );
        gals.set("halign", "right");
        gals.set("live", 1);

        var per = tcell(fuelTable, "text", i+1, 5);
        per.set("property", tankprop ~ "/level-norm");
        per.set("label", "0123456");
        per.set("format", "%.2f");
        per.set("halign", "right");
        per.set("live", 1);
    }

    varbar = tcell(fuelTable, "hrule", size(tanks)+1, 0);
    varbar.set("colspan", 6);

    var total_label = tcell(fuelTable, "text", size(tanks)+2, 2);
    total_label.set("label", "Total:");
    total_label.set("halign", "right");

    var lbs = tcell(fuelTable, "text", size(tanks)+2, 3);
    lbs.set("property", "/consumables/fuel/total-fuel-lbs");
    lbs.set("label", "0123456");
    lbs.set("format", "%.1f" );
    lbs.set("halign", "right");
    lbs.set("live", 1);

    var gals = tcell(fuelTable, "text",size(tanks) +2, 4);
    gals.set("property", "/consumables/fuel/total-fuel-gal_us");
    gals.set("label", "0123456");
    gals.set("format", "%.1f" );
    gals.set("halign", "right");
    gals.set("live", 1);

    var per = tcell(fuelTable, "text", size(tanks)+2, 5);
    per.set("property", "/consumables/fuel/total-fuel-norm");
    per.set("label", "0123456");
    per.set("format", "%.2f");
    per.set("halign", "right");
    per.set("live", 1);

    var weightArea = contentArea.addChild("group");
    weightArea.set("layout", "vbox");
    weightArea.addChild("text").set("label", "Payload");

    var weightTable = weightArea.addChild("group");
    weightTable.set("layout", "table");

    weightArea.addChild("empty").set("stretch", 1);

    tcell(weightTable, "text", 0, 0).set("label", "Location");
    tcell(weightTable, "text", 0, 2).set("label", "Pounds");

    var payload_base = props.globals.getNode(fdmdata.payload);
    if (payload_base != nil)
        var wgts = payload_base.getChildren("weight");
    else
        var wgts = [];
    for(var i=0; i<size(wgts); i+=1) {
        var w = wgts[i];
        var wname = w.getNode("name", 1).getValue();
        var wprop = fdmdata.payload ~ "/weight[" ~ i ~ "]";

        var title = tcell(weightTable, "text", i+1, 0);
        title.set("label", wname);
        title.set("halign", "right");

        if(w.getNode("opt") != nil) {
            var combo = tcell(weightTable, "combo", i+1, 1);
            combo.set("property", wprop ~ "/selected");
            combo.set("pref-width", 300);

            # Simple code we'd like to use:
            #foreach(opt; w.getChildren("opt")) {
            #    var ent = combo.addChild("value");
            #    ent.prop().setValue(opt.getNode("name", 1).getValue());
            #}

            # More complicated workaround to move the "current" item
            # into the first slot, because dialog.cxx doesn't set the
            # selected item in the combo box.
            var opts = [];
            var curr = w.getNode("selected");
            curr = curr == nil ? "" : curr.getValue();
            foreach(opt; w.getChildren("opt")) {
                append(opts, opt.getNode("name", 1).getValue());
            }
            forindex(oi; opts) {
                if(opts[oi] == curr) {
                    var tmp = opts[0];
                    opts[0] = opts[oi];
                    opts[oi] = tmp;
                    break;
                }
            }
            foreach(opt; opts) {
                combo.addChild("value").prop().setValue(opt);
            }

            combo.setBinding("dialog-apply");
            combo.setBinding("nasal", "gui.weightChangeHandler()");
        } else {
            var slider = tcell(weightTable, "slider", i+1, 1);
            slider.set("property", wprop ~ "/weight-lb");
            var min = w.getNode("min-lb", 1).getValue();
            var max = w.getNode("max-lb", 1).getValue();
            slider.set("min", min != nil ? min : 0);
            slider.set("max", max != nil ? max : 100);
            slider.set("live", 1);
            slider.setBinding("dialog-apply");
        }

        var lbs = tcell(weightTable, "text", i+1, 2);
        lbs.set("property", wprop ~ "/weight-lb");
        lbs.set("label", "0123456");
        lbs.set("format", "%.0f");
        lbs.set("live", 1);
    }

    var bar = tcell(weightTable, "hrule", size(wgts)+1, 0);
    bar.set("colspan", 5);

    var total_label = tcell(weightTable, "text", size(wgts)+2, 0);
    total_label.set("label", "Total Load/Passengers");
    total_label.set("halign", "left");

    var lbs = tcell(weightTable, "text",size(wgts) +2, 2);
    lbs.set("property", "b707/passengers/load-weight");
    lbs.set("label", "0123456");
    lbs.set("format", "%.0f" );
    lbs.set("halign", "right");
    lbs.set("live", 1);
    

    # All done: pop it up
    fgcommand("dialog-new", dialog[name].prop());
    gui.showDialog(name);
}


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
    showAircraftPayloadDialog();
    beltSwitchListenerId = setlistener(SEAT_BELT_SWITCH_PROP, beltSwitchSlot);
    mainloopTimer.start();
    setprop("/sim/messages/copilot", "Start boarding");
}



_setlistener("/sim/signals/nasal-dir-initialized", moduleInit);
