var LandingNotification = 
{
		SHOW_TIME: 10.0,
		SLICE: 17,
		MARGIN: 10,

	new: func
	{
		var m = {
			parents: [LandingNotification, canvas.PropertyElement.new(["/sim/gui/canvas", "window"], nil)],
			_title: "",
		};

		m.setInt("size[0]", 500);
		m.setInt("size[1]", 400);
		m.setBool("visible", 0);
		m.setInt("z-index", canvas.gui.STACK_INDEX["always-on-top"]);

		m._hideTimer = maketimer(m.SHOW_TIME, m, LandingNotification._hideTimeout);
		m._hideTimer.singleShot = 1;

		return m;
	},

	# Destructor
	del: func {
		logprint(LOG_DEBUG, "Deleting landing notification");
		setprop("/addons/by-id/org.flightgear.addons.landing-challenge/addon-devel/old-index", me._node.getIndex());
		print("OLDINDEX", getprop("/addons/by-id/org.flightgear.addons.landing-challenge/addon-devel/old-index"));
		
		call(me.parents[1].del, nil, nil, var err = []);
		if (me["_canvas"] != nil) {
			me._canvas.del();
		}
	},

	_createCanvas: func() {
		var size = [
			me.get("size[0]"),
			me.get("size[1]")
		];

		me._canvas = canvas.new({
			size: [2 * size[0], 2 * size[1]],
			view: size,
			placement: {
				type: "window",
				index: me._node.getIndex()
			},
			name: "Landing Notification"
		});

		me.set("capture-events", 1);
		me.set("fill", "rgba(255,255,255,0.8)");

		# transparent background
		me._canvas.setColorBackground(0.0, 0.0, 0.0, 0.0);

		var root = me._canvas.createGroup();
		me._root = root;

		me._frame =
			root.createChild("image", "background")
					.set("src", addonBasePath ~ "/gui/images/tooltip.png")
					.set("slice", me.SLICE ~ " fill")
					.setSize(size);

		me._warningIcon =
			root.createChild("image", "warning-icon")
					.set("src", addonBasePath ~ "/gui/images/planeLanding.png")
					.setTranslation(me.SLICE, me.SLICE);

		var iconWidth = me._warningIcon.get("size[0]");

		me._text =
			root.createChild("text", "landing-description")
					.setText("You landed!\n\n Click for more details...")
					.setAlignment("left-top")
					.setFontSize(14)
					.setFont("LiberationFonts/LiberationSans-Bold.ttf")
					.setColor(1,1,1)
					.setDrawMode(canvas.Text.TEXT)
					.setTranslation(me.SLICE + iconWidth + me.MARGIN, me.SLICE);

		 me._canvas.addEventListener("mousedown", func me.clicked());
		 
		return me._canvas;
	},

	clicked: func() {
		me.hideNow();
		fgcommand("show-landing-data-dialog");		
	},

 	_updateBounds: func {
		# the width of everything except the text
		var extraWidth = me._warningIcon.get("size[0]") + me.MARGIN + (2 * me.SLICE);
		var maxTextWidth = me.get("size[0]") - extraWidth;

		me._text.setMaxWidth(maxTextWidth);

		# compute the bounds
		var text_bb = me._text.update().getBoundingBox();
		var width = text_bb[2];
		var height = text_bb[3];

		if( width > maxTextWidth )
			width = maxTextWidth;

		me._width = width + extraWidth;
		me._height = height + 2 * me.SLICE;
		me._frame.setSize(me._width, me._height)
						 .update();

		me._updatePosition();
	},

	_updatePosition: func
	{
		var INSET = 50;
		var y = INSET;
		var x = getprop('/sim/startup/xsize') - (me._width + INSET);

		me.setInt("x", x);
		me.setInt("y", y);
	},

	show: func()
	{
		me._hideTimer.stop();
		me.setBool("visible", 1);
		me._hideTimer.start();
	},

	hideNow: func()
	{
		me._hideTimer.stop();
		me._hideTimeout();
	},

	_hideTimeout: func()
	{
		me.setBool("visible", 0);
	}
};

var landingNotificationCanvas = nil;

var showLandingNotification = func() {
	logprint(LOG_DEBUG, "Showing landing notification");
	
	# if there was a canvas node left behind due to plugin reload, delete it
	if (var oldIndex = getprop("/addons/by-id/org.flightgear.addons.landing-challenge/addon-devel/old-index") > -1) {
		props.getNode("/sim/gui/canvas/window[" ~ oldIndex ~ "]").remove();
		setprop("/addons/by-id/org.flightgear.addons.landing-challenge/addon-devel/old-index", -1);
	}
	
	if (landingNotificationCanvas == nil) {
		landingNotificationCanvas = LandingNotification.new();
		landingNotificationCanvas._createCanvas();
	}
	landingNotificationCanvas._updateBounds();
	landingNotificationCanvas.show();
}

addcommand("show-landing-notification-popup", showLandingNotification);
