var PROPPATH = "/addons/by-id/org.flightgear.addons.landing-challenge/addon-devel/landing-data/";
var ICONMARGIN = 60;
var ICONWIDTH = 64;
var ICONHEIGHT = 64;

var showLandingDataDialog = func() {
	# get landing data from the property tree
	var offcenter = -num(getprop(PROPPATH ~ "offcenter"));
	var overshoot = -num(getprop(PROPPATH ~ "overshoot"));
	var sideslipAngle = getprop(PROPPATH ~ "slip-angle");
	var bankAngle = getprop(PROPPATH ~ "bank-angle");
	var pitchAngle = getprop(PROPPATH ~ "pitch-angle");
	var vsFPM = getprop(PROPPATH ~ "fpm");
	var gForce = getprop(PROPPATH ~ "g-force");
	var airspeed = getprop(PROPPATH ~ "airspeed");
	var groundspeed = getprop(PROPPATH ~ "groundspeed");
	
	# limit the offcenter distance shown - one icon would else be hidden by the previous if offcenter is very much
	var offcentergeom = 0;
	if (offcenter > ICONWIDTH / 2) {
		offcentergeom = ICONWIDTH / 2;
	} elsif (offcenter < -ICONWIDTH) {
		offcentergeom = -(ICONWIDTH / 2);
	} else {
		offcentergeom = offcenter;
	}
	
	var overshootgeom = 0;
	if (overshoot > ICONHEIGHT / 2) {
		overshootgeom = ICONHEIGHT / 2;
	} elsif (overshoot < -ICONHEIGHT) {
		overshootgeom = -(ICONHEIGHT / 2);
	} else {
		overshootgeom = overshoot;
	}
	
	var vsFPMgeom = 0;
	# limit vertical speed shown so the needle doesn't deflect too much
	if (vsFPM > 1400) {
		vsFPMgeom = 1400;
	} elsif (vsFPM < -1400) {
		vsFPMgeom = -1400;
	} else {
		vsFPMgeom = vsFPM;
	}
	vsFPMgeom = 45 * vsFPMgeom / 500;
	
	var dialog = canvas.Window.new([780, 400], "dialog").setTitle("Landing data");
	var dialogCanvas = dialog.createCanvas(1).set("background", "#ffffff");
	var rootGroup = dialogCanvas.createGroup();
#	var rootBox = canvas.VBoxLayout.new();
#	rootBox.setContentsMargin(10);
#	dialog.setLayout(rootBox);
	
	var deviationImageGroup = rootGroup.createChild("group");
	canvas.parsesvg(deviationImageGroup, "[addon=org.flightgear.addons.landing-challenge]gui/images/threshold-deviation.svg");
	deviationImageGroup.setTranslation(ICONMARGIN, ICONMARGIN);
	
	var deviationImageGroupAirplane = deviationImageGroup.getElementById("airplane");
	deviationImageGroupAirplane.setTranslation(offcentergeom, overshootgeom);
	deviationImageGroupAirplane.setRotation(sideslipAngle * D2R); # need to convert here because slip-angle is in degrees but setRotation needs radians
	deviationText = rootGroup.createChild("text");
	deviationText.setColor(0, 0, 0, 1);
	deviationText.setAlignment("center-top");
	deviationText.setFontSize(15, 1);
	deviationText.setTranslation(ICONMARGIN + (ICONWIDTH / 2), (ICONMARGIN * 2) + ICONHEIGHT);
	deviationText.setText("Target\ndistance:\n" ~ abs(overshoot) ~ "\n\nCenterline\ndistance:\n" ~ abs(offcenter) ~ "\n\nSideslip\nangle:\n" ~ sideslipAngle);
	
	var bankIndicatorGroup = rootGroup.createChild("group");
	canvas.parsesvg(bankIndicatorGroup, "[addon=org.flightgear.addons.landing-challenge]gui/images/bank-indicator.svg");
	bankIndicatorGroup.setTranslation(ICONMARGIN * 2 + ICONWIDTH, ICONMARGIN);
	
	var bankIndicatorAirplane = bankIndicatorGroup.getElementById("airplane");
	bankIndicatorAirplane.setRotation(bankAngle * D2R);

	bankText = rootGroup.createChild("text");
	bankText.setColor(0, 0, 0, 1);
	bankText.setAlignment("center-top");
	bankText.setFontSize(15, 1);
	bankText.setTranslation(ICONMARGIN * 2 + (ICONWIDTH / 2) + ICONWIDTH, (ICONMARGIN * 2) + ICONHEIGHT);
	bankText.setText("Bank angle:\n" ~ bankAngle);
	
	
	var vsiIndicatorGroup = rootGroup.createChild("group");
	canvas.parsesvg(vsiIndicatorGroup, "[addon=org.flightgear.addons.landing-challenge]gui/images/vsi-indicator.svg");
	vsiIndicatorGroup.setTranslation(ICONMARGIN * 3 + ICONWIDTH * 2, ICONMARGIN);
	
	var vsiIndicatorNeedle = vsiIndicatorGroup.getElementById("needle");
	vsiIndicatorNeedle.setRotation(vsFPMgeom * D2R);

	vsiText = rootGroup.createChild("text");
	vsiText.setColor(0, 0, 0, 1);
	vsiText.setAlignment("center-top");
	vsiText.setFontSize(15, 1);
	vsiText.setTranslation(ICONMARGIN * 3 + (ICONWIDTH / 2) + ICONWIDTH * 2, (ICONMARGIN * 2) + ICONHEIGHT);
	vsiText.setText("Vertical\nspeed:\n" ~ vsFPM);
	
	
	var gForceIconGroup = rootGroup.createChild("group");
	canvas.parsesvg(gForceIconGroup, "[addon=org.flightgear.addons.landing-challenge]gui/images/g-force.svg");
	gForceIconGroup.setTranslation(ICONMARGIN * 4 + ICONWIDTH * 3, ICONMARGIN);
	gForceIconGroup.setScale(gForce);
	
	gForceText = rootGroup.createChild("text");
	gForceText.setColor(0, 0, 0, 1);
	gForceText.setAlignment("center-top");
	gForceText.setFontSize(15, 1);
	gForceText.setTranslation(ICONMARGIN * 4 + (ICONWIDTH / 2) + ICONWIDTH * 3, (ICONMARGIN * 2) + ICONHEIGHT);
	gForceText.setText("G-Force:\n" ~ gForce);
	
	
	var sideviewGroup = rootGroup.createChild("group");
	canvas.parsesvg(sideviewGroup, "[addon=org.flightgear.addons.landing-challenge]gui/images/sideview.svg");
	sideviewGroup.setTranslation(ICONMARGIN * 5 + ICONWIDTH * 4, ICONMARGIN);
	
	var sideviewAirplane = sideviewGroup.getElementById("airplane");
	sideviewAirplane.setRotation(pitchAngle * D2R);
	
	sideviewText = rootGroup.createChild("text");
	sideviewText.setColor(0, 0, 0, 1);
	sideviewText.setAlignment("center-top");
	sideviewText.setFontSize(15, 1);
	sideviewText.setTranslation(ICONMARGIN * 5 + (ICONWIDTH / 2) + ICONWIDTH * 4, (ICONMARGIN * 2) + ICONHEIGHT);
	sideviewText.setText("Pitch\nangle:\n" ~ pitchAngle ~ "\n\nAirspeed:\n" ~ airspeed ~ "\n\nGroundspeed\n" ~ groundspeed);
}

addcommand("show-landing-data-dialog", showLandingDataDialog);
