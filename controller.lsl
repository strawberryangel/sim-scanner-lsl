#include "lib/avatar.lsl"
#include "lib/channels.lsl"
#include "lib/debug.lsl"
#include "lib/say.lsl"
#include "lib/whitelist/blackpaw-avatars.lsl"
#include "sim-scanner-lsl/lib.lsl"

string VERSION = "1.1.2";
				
string PACKAGE_VERSION = "1.5.2";

key owner_key;


///////////////////////////////////////
// Menu
///////////////////////////////////////

integer is_configured = FALSE;
integer channel;

integer configure_channel = -1;
string BUTTON_PRODUCTION = "Production";
string BUTTON_DEVELOPMENT = "Development";
string BUTTON_START = "Done";
string BUTTON_PARCEL = "Parcel";
string BUTTON_OWNED = "Owned";
string BUTTON_REGION = "Region";
string BUTTON_WHITE = "White";
string BUTTON_RED = "Red";
string BUTTON_GREEN = "Green";
string BUTTON_OFF = "Hide";
string BUTTON_OWNER = "Owner";
string BUTTON_GROUP = "Group";


show_configuration_menu(key who)
{
	list buttons;
	if(who == WL_Sophie)
		buttons = [
			BUTTON_PRODUCTION,
		BUTTON_START,
		BUTTON_DEVELOPMENT,

		BUTTON_OFF,
		BUTTON_OWNER,
		BUTTON_GROUP,

		BUTTON_GREEN,
		BUTTON_RED,
		BUTTON_WHITE,

		BUTTON_PARCEL,
		BUTTON_OWNED,
		BUTTON_REGION
			];
	else
		buttons = [
			" ",
		BUTTON_START,
		" ",

		BUTTON_GREEN,
		BUTTON_RED,
		BUTTON_WHITE,

		BUTTON_OWNER,
		BUTTON_GROUP,
		BUTTON_OFF,

		BUTTON_PARCEL,
		BUTTON_OWNED,
		BUTTON_REGION
			];

	string CONFIGURATION_MENU = "Black Paw IoT Avatar Sensor Configuration\n"+
		"Parcel - Only scan this parcel\n" +
		"Owned - Only scan owned parcels in this region.\n" +
		"Region - Scan the entire region.\n \n" +
		"Owner/Group - Who may configure this sensor.\n \n" +
		"Color - Set display color\n"  +
		"Hide - Hide display";

	llDialog(who, CONFIGURATION_MENU, buttons, configure_channel);
}

///////////////////////////////////////
// Scanner Configuration
///////////////////////////////////////

configure_parcel()
{
	llMessageLinked(LINK_SET, LINK_COMMAND_CONFIGURE_SCANNER, SCANNER_CONFIG_PARCEL, NULL_KEY);
	report_versions();
}

configure_owned()
{
	llMessageLinked(LINK_SET, LINK_COMMAND_CONFIGURE_SCANNER, SCANNER_CONFIG_OWNED, NULL_KEY);
	report_versions();
}

configure_region()
{
	llMessageLinked(LINK_SET, LINK_COMMAND_CONFIGURE_SCANNER, SCANNER_CONFIG_REGION, NULL_KEY);
	report_versions();
}

///////////////////////////////////////
// Transmitter Configuration
///////////////////////////////////////

configure_development()
{
	llMessageLinked(LINK_SET, LINK_COMMAND_CONFIGURE_SERVER, TRANSMITTER_CONFIG_DEVELOPMENT, NULL_KEY);
	report_versions();
}

configure_production()
{
	llMessageLinked(LINK_SET, LINK_COMMAND_CONFIGURE_SERVER, TRANSMITTER_CONFIG_PRODUCTION, NULL_KEY);
	report_versions();
}

///////////////////////////////////////
// Support Functions
///////////////////////////////////////

// Text settings
string hover_text = "";
vector text_color = <0,1,0>;
float text_alpha = 1.0;

// Access settings
integer ACCESS_OWNER = 0;
integer ACCESS_GROUP = 1;
integer access = ACCESS_OWNER;

greet_owner()
{
	debug("Hello " + format_name(owner_key));
	debug("The controller is starting.");
}

handle_version_report(string message)
{
	list parts = llParseString2List(message, ["|"], []);

	if(llGetListLength(parts) != 2)
	{
		llOwnerSay("Unexpected message returned from version request: " + message);
		return;
	}
	string origin = llList2String(parts, 0);
	string version = llList2String(parts, 1);
	if(origin == SCRIPT_SCANNER)
	{
		hover_text += "\n" + version;
		debug("Scanner " + version);
		update_text();
	}
	if(origin == SCRIPT_TRANSMITTER)
	{
		hover_text += "\n" + version;
		debug("Transmitter " + version);
		update_text();
	}
}

integer is_authorized(key who)
{
	if(who == owner_key || who == WL_Sophie) return TRUE;

	return access == ACCESS_GROUP && llSameGroup(who);
}

report_versions()
{
	hover_text = "Black Paw IoT Avatar Sensor v" + PACKAGE_VERSION + "\nController v" + VERSION;

	debug("Black Paw IoT Avatar Sensor");
	debug("Controller v" + VERSION);
	llMessageLinked(LINK_SET, LINK_COMMAND_REPORT_VERSION, "", NULL_KEY);
}


set_access_group()
{
	access = ACCESS_GROUP;
}

set_access_owner()
{
	access = ACCESS_OWNER;
}

set_colors(vector color, float alpha)
{
	text_color = color;
	text_alpha = alpha;

	// Refresh display
	report_versions();
}

set_owner()
{
	owner_key = llGetOwner();

	// See documentation on llFRand http://wiki.secondlife.com/wiki/LlFrand
	configure_channel = -1 * ((integer)llFrand(500)*1000000 + (integer)llFrand(1000000));

	llListenRemove(channel);
	channel = llListen(configure_channel, "", NULL_KEY, "");
}

update_text()
{
	llSetText(hover_text, text_color, text_alpha);
}

default
{
	changed(integer change)
	{
		if(change & CHANGED_OWNER)
		{
			set_owner();
			greet_owner();
		}
	}

	link_message(integer sender_number, integer number, string message, key id)
	{
		if(number == LINK_COMMAND_REPORT_VERSION && message != "") handle_version_report(message);
	}

	listen(integer channel, string name, key id, string message)
	{
		if(channel != configure_channel) return;

		if(message == BUTTON_START)
		{
			report_versions();
			return;
		}

		if(message == BUTTON_DEVELOPMENT) configure_development();
		if(message == BUTTON_PRODUCTION) configure_production();

		if(message == BUTTON_PARCEL) configure_parcel();
		if(message == BUTTON_OWNED) configure_owned();
		if(message == BUTTON_REGION) configure_region();

		if(message == BUTTON_OWNER) set_access_owner();
		if(message == BUTTON_GROUP) set_access_group();

		if(message == BUTTON_WHITE) set_colors(<1,1,1>, 1);
		if(message == BUTTON_RED) set_colors(<1,0,0>, 0.7);
		if(message == BUTTON_GREEN) set_colors(<0,1,0>, 1);
		if(message == BUTTON_OFF) set_colors(<1,1,1>, 0);

		show_configuration_menu(id);
	}

	state_entry()
	{
		DEBUG = FALSE; // DEBUG_STYLE_OWNER;
		set_owner();
		greet_owner();

		// Initialize display.
		report_versions();
	}

	touch_end(integer total_number)
	{
		key who = llDetectedKey(0);
		if(is_authorized(who))
		{
			// Refresh display to ensure the display is current.
			report_versions();
			show_configuration_menu(who);
		}
	}
}
