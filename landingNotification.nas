var LandingNotification = {
	SHOW_TIME: 10.0,
	SLICE: 17,
	MARGIN: 10,

	new: func {
		var obj = {
			parents: [LandingNotification, canvas.PropertyElement.new(["/sim/gui/canvas", "window"], nil)],
			_title: "",
		};

		obj.setInt("size[0]", 500);
		obj.setInt("size[1]", 400);
		obj.setBool("visible", 0);
		obj.setInt("z-index", canvas.gui.STACK_INDEX["always-on-top"]);

		obj._hideTimer = maketimer(obj.SHOW_TIME, obj, LandingNotification.hide);
		obj._hideTimer.singleShot = 1;

		return obj;
	},

	# Destructor
	del: func {
		me.parents[1].del();
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
		me.hide();
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

	hide: func()
	{
		me._hideTimer.stop();
		me.setBool("visible", 0);
	}
};

var landingNotification = nil;

var showLandingNotification = func() {
	if (landingNotification == nil) {
		landingNotification = LandingNotification.new();
		landingNotification._createCanvas();
	}
	landingNotification._updateBounds();
	landingNotification.show();
}

addcommand("show-landing-notification", showLandingNotification);
