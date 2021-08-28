var showLandingDataDialog = func() {
	var dialog = canvas.Window.new([300,120], "dialog").setTitle("Landing data");
	var root = dialog.getCanvas(1).set("background", "#ffffff").createGroup();
	var rootBox = canvas.VBoxLayout.new();
	rootBox.setContentsMargin(10);
	dialog.setLayout(rootBox);
	
	orientationPositionLabel = canvas.gui.widgets.Label.new(root, canvas.style, {wordWrap: 1}).setText("Orientation and Position");
	rootBox.addItem(orientationPositionLabel);
	
	orientationPositionBox = canvas.HBoxLayout.new();
	orientationPositionBox.setContentsMargin(10);
	
	deviationBox = canvas.VBoxLayout.new();
	deviationImageGroup = root.createChild("group");
	canvas.parsesvg(deviationImageGroup, "[addon=org.flightgear.addons.landing-challenge]gui/images/threshold-deviation.svg");
	
	orientationPositionBox.addItem(deviationBox);
	
	rootBox.addItem(orientationPositionBox);
	
}

addcommand("show-landing-data-dialog", showLandingDataDialog);
