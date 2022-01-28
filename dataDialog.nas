var LandingDataDialog = {
	new: func {
		var obj = {
			parents: [LandingDataDialog, canvas.Window.new([780, 400], "dialog").setTitle("Landing data")],
			dataNode: props.globals.getNode("/addons/by-id/org.flightgear.addons.landing-challenge/addon-devel/landing-data"),
			ICONMARGIN: 60,
			ICONWIDTH: 64,
			ICONHEIGHT: 64,
		};
		
		obj.offcenterNode = obj.dataNode.getNode("offcenter-m");
		obj.overshootNode = obj.dataNode.getNode("overshoot-m");
		obj.sideslipNode = obj.dataNode.getNode("sideslip-deg");
		obj.rollNode = obj.dataNode.getNode("roll-deg");
		obj.pitchNode = obj.dataNode.getNode("pitch-deg");
		obj.verticalSpeedNode = obj.dataNode.getNode("vertical-speed-fpm");
		obj.gForceNode = obj.dataNode.getNode("g-force");
		obj.airspeedNode = obj.dataNode.getNode("airspeed-kt");
		obj.groundspeedNode = obj.dataNode.getNode("groundspeed-kt");
		
		obj.canvas = obj.parents[1].createCanvas(1);
		obj.canvas.set("background", "#ffffff");
		obj.group = obj.canvas.createGroup();
		
		obj.deviationIcon = obj.group.createChild("group");
		canvas.parsesvg(obj.deviationIcon, "[addon=org.flightgear.addons.landing-challenge]gui/images/threshold-deviation.svg");
		obj.deviationIcon.setTranslation(obj.ICONMARGIN, obj.ICONMARGIN);
		
		obj.deviationIconAirplane = obj.deviationIcon.getElementById("airplane");
		obj.deviationText = obj.group.createChild("text")
						.setColor(0, 0, 0, 1)
						.setAlignment("center-top")
						.setFontSize(15, 1)
						.setTranslation(obj.ICONMARGIN + (obj.ICONWIDTH / 2), (obj.ICONMARGIN * 2) + obj.ICONHEIGHT);
		
		obj.rollIcon = obj.group.createChild("group")
						.setTranslation(obj.ICONMARGIN * 2 + obj.ICONWIDTH, obj.ICONMARGIN);
		canvas.parsesvg(obj.rollIcon, "[addon=org.flightgear.addons.landing-challenge]gui/images/bank-indicator.svg");
		
		obj.rollIconAirplane = obj.rollIcon.getElementById("airplane");
		
		obj.rollText = obj.group.createChild("text")
						.setColor(0, 0, 0, 1)
						.setAlignment("center-top")
						.setFontSize(15, 1)
						.setTranslation(obj.ICONMARGIN * 2 + (obj.ICONWIDTH / 2) + obj.ICONWIDTH, (obj.ICONMARGIN * 2) + obj.ICONHEIGHT);
		
		obj.verticalSpeedIcon = obj.group.createChild("group")
						.setTranslation(obj.ICONMARGIN * 3 + obj.ICONWIDTH * 2, obj.ICONMARGIN);
		canvas.parsesvg(obj.verticalSpeedIcon, "[addon=org.flightgear.addons.landing-challenge]gui/images/vsi-indicator.svg");
		
		obj.verticalSpeedIconNeedle = obj.verticalSpeedIcon.getElementById("needle");
		
		obj.verticalSpeedText = obj.group.createChild("text")
						.setColor(0, 0, 0, 1)
						.setAlignment("center-top")
						.setFontSize(15, 1)
						.setTranslation(obj.ICONMARGIN * 3 + (obj.ICONWIDTH / 2) + obj.ICONWIDTH * 2, (obj.ICONMARGIN * 2) + obj.ICONHEIGHT);
		
		obj.gForceIcon = obj.group.createChild("group")
						.setTranslation(obj.ICONMARGIN * 4 + obj.ICONWIDTH * 3, obj.ICONMARGIN);
		canvas.parsesvg(obj.gForceIcon, "[addon=org.flightgear.addons.landing-challenge]gui/images/g-force.svg");
		
		obj.gForceText = obj.group.createChild("text")
						.setColor(0, 0, 0, 1)
						.setAlignment("center-top")
						.setFontSize(15, 1)
						.setTranslation(obj.ICONMARGIN * 4 + (obj.ICONWIDTH / 2) + obj.ICONWIDTH * 3, (obj.ICONMARGIN * 2) + obj.ICONHEIGHT);
		
		obj.sideviewIcon = obj.group.createChild("group")
						.setTranslation(obj.ICONMARGIN * 5 + obj.ICONWIDTH * 4, obj.ICONMARGIN);
		canvas.parsesvg(obj.sideviewIcon, "[addon=org.flightgear.addons.landing-challenge]gui/images/sideview.svg");
		
		obj.sideviewIconAirplane = obj.sideviewIcon.getElementById("airplane");
		
		obj.sideviewText = obj.group.createChild("text")
						.setColor(0, 0, 0, 1)
						.setAlignment("center-top")
						.setFontSize(15, 1)
						.setTranslation(obj.ICONMARGIN * 5 + (obj.ICONWIDTH / 2) + obj.ICONWIDTH * 4, (obj.ICONMARGIN * 2) + obj.ICONHEIGHT);
		
		return obj;
	},
	
	update: func {
		var sideslipAngle = me.sideslipNode.getValue();
		var offcenter = me.offcenterNode.getValue();
		var overshoot = me.overshootNode.getValue();
		var rollAngle = me.rollNode.getValue();
		var verticalSpeed = me.verticalSpeedNode.getValue();
		var gForce = me.gForceNode.getValue();
		var pitchAngle = me.pitchNode.getValue();
		var airspeed = me.airspeedNode.getValue();
		var groundspeed = me.groundspeedNode.getValue();
		
		me.deviationIconAirplane.setRotation(sideslipAngle * D2R);
		me.deviationIconAirplane.setTranslation(math.clamp(offcenter, -me.ICONWIDTH / 2, me.ICONWIDTH / 2), math.clamp(overshoot, -me.ICONHEIGHT / 2, me.ICONHEIGHT / 2));
		me.rollIconAirplane.setRotation(rollAngle * D2R);
		me.verticalSpeedIconNeedle.setRotation((45 * math.clamp(verticalSpeed, -1400, 1400) / 500) * D2R);
		me.gForceIcon.setScale(gForce);
		me.sideviewIconAirplane.setRotation(pitchAngle * D2R);
		
		me.deviationText.setText("Target\ndistance:\n" ~ abs(overshoot) ~ " ft\n\nCenterline\ndistance:\n" ~ abs(offcenter) ~ " ft\n\nSideslip\nangle:\n" ~ abs(sideslipAngle) ~ " deg");
		me.rollText.setText("Bank angle:\n" ~ rollAngle ~ " deg");
		me.verticalSpeedText.setText("Vertical\nspeed:\n" ~ verticalSpeed ~ " FPM");
		me.gForceText.setText("G-Force:\n" ~ gForce);
		me.sideviewText.setText("Pitch\nangle:\n" ~ pitchAngle ~ " deg\n\nAirspeed:\n" ~ airspeed ~ " kts\n\nGroundspeed\n" ~ groundspeed ~ " kts");
	}
};

var landingDataDialog = nil;

var showLandingDataDialog = func {
	if (landingDataDialog == nil) {
		landingDataDialog = LandingDataDialog.new();
	}
	landingDataDialog.update();
	landingDataDialog.show();
}

addcommand("show-landing-data-dialog", showLandingDataDialog);
