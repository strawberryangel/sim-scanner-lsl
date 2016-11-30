#include "sim-scanner-lsl/lib.lsl"

	string VERSION = "1.0.0";

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
	if(origin == SCRIPT_SCANNER) llOwnerSay("Scanner " + version);
	if(origin == SCRIPT_TRANSMITTER) llOwnerSay("Transmitter " + version);
}

configure_development()
{
	llMessageLinked(LINK_SET, LINK_COMMAND_CONFIGURE_SERVER, CONFIG_DEVELOPMENT, NULL_KEY);
}


configure_production()
{
	llMessageLinked(LINK_SET, LINK_COMMAND_CONFIGURE_SERVER, CONFIG_PRODUCTION, NULL_KEY);
}

report_versions()
{
	llOwnerSay("Black Paw IoT Avatar Sensor");
	llOwnerSay("Controller v" + VERSION);
	llMessageLinked(LINK_SET, LINK_COMMAND_REPORT_VERSION, "", NULL_KEY);
}

integer a = TRUE;


default
{
	link_message(integer sender_number, integer number, string message, key id)
	{
		if(number == LINK_COMMAND_REPORT_VERSION && message != "") handle_version_report(message);
	}

	state_entry()
	{
	}

	touch_end(integer total_number)
	{
		llOwnerSay(" asdlkfj");
		a =!a;
		if(a)
			configure_development();
		else
			configure_production();

		report_versions();
	}
}
