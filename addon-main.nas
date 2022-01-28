# This file is part of FlightGear.
#
# FlightGear is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# FlightGear is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with FlightGear. If not, see <http://www.gnu.org/licenses/>.

# This is the main addon Nasal hook. It MUST contain a function
# called "main". The main function will be called upon init with
# the addons.Addon instance corresponding to the addon being loaded.
#
# This script will live in its own Nasal namespace that gets
# dynamically created from the global addon init script.
# It will be something like "__addon[ADDON_ID]__" where ADDON_ID is
# the addon identifier, such as "org.flightgear.addons.Skeleton".
#
# See $FG_ROOT/Docs/README.add-ons for info about the addons.Addon
# object that is passed to main(), and much more. The latest version
# of this README.add-ons document is at:
#
#	 https://sourceforge.net/p/flightgear/fgdata/ci/next/tree/Docs/README.add-ons
#

#
# Copyright (C) 2021 D. Meissner (danielHL.83@googlemail.com) 
#
# Based on landing-rate addon by RenanMsV (https://github.com/RenanMsV/landing_rate)
#

var namespace = "LDG";

var unload = func(addon) {
	logprint(LOG_DEBUG, "Unloading landing challenge plugin");
	if (globals[namespace].landingNotification != nil) {
		globals[namespace].landingNotification.del();
	}
	delete(globals, namespace);
	removecommand("show-landing-notification-popup");
	removecommand("show-landing-data-dialog");
}

var main = func(addon) {
	logprint(LOG_INFO, "Landing-Challenge addon initialized from path ", addon.basePath);
	
	io.load_nasal(addon.basePath ~ "/landingChallenge.nas", namespace);
	io.load_nasal(addon.basePath ~ "/landingNotification.nas", namespace);
	io.load_nasal(addon.basePath ~ "/dataDialog.nas", namespace);
	globals[namespace].addonBasePath = addon.basePath;
	
}
