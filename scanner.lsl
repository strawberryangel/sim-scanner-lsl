#include "sim-scanner-lsl/lib.lsl"
	#include "sim-scanner-lsl/main.h"
		#include "lib/channels.lsl"
			#include "lib/debug.lsl"

				string VERSION = "1.5.0";

integer scope = AGENT_LIST_PARCEL_OWNER;

///////////////////////////////////////////////////
// Version reporting.
///////////////////////////////////////////////////

report_configuration()
{
	llMessageLinked(LINK_SET, LINK_COMMAND_REPORT_VERSION, SCRIPT_SCANNER + "|Scanner v" + VERSION, NULL_KEY);

	if(scope == AGENT_LIST_PARCEL)
		llMessageLinked(LINK_SET, LINK_COMMAND_REPORT_VERSION, SCRIPT_SCANNER + "|The scanner is limited to the parcel it rests on.", NULL_KEY);
	else  if(scope == AGENT_LIST_PARCEL_OWNER)
		llMessageLinked(LINK_SET, LINK_COMMAND_REPORT_VERSION, SCRIPT_SCANNER + "|The scanner is limited to owned parcels.", NULL_KEY);
	else if (scope == AGENT_LIST_REGION)
		llMessageLinked(LINK_SET, LINK_COMMAND_REPORT_VERSION, SCRIPT_SCANNER + "|The scanner reaches the entire region.", NULL_KEY);
	else
		llMessageLinked(LINK_SET, LINK_COMMAND_REPORT_VERSION, SCRIPT_SCANNER + "|The scanner's reach is undefined. This is an unexpected state.", NULL_KEY);
}

///////////////////////////////////////////////////
//
// This is the actual scanner.
//
///////////////////////////////////////////////////
scan()
{
	list agents = llGetAgentList(scope, []);
	integer count = llGetListLength(agents);
	integer start = 0;
	integer stop;

	debug("Number of Avatars: " + (string)count);

	while(start < count)
	{
		stop = start + SLICE_SIZE - 1;
		if(stop >= count) stop = count-1;

		list slice = llList2List(agents, start, stop);
		string bundle = llDumpList2String(slice, BUNDLE_DELIMITER);

		debug(bundle);

		llMessageLinked(LINK_SET, LM_TRANSMITTER, bundle, NULL_KEY);

		start = stop + 1;
	}
}

default
{
	link_message(integer sender_number, integer number, string message, key id)
	{
		if(number == LINK_COMMAND_REPORT_VERSION && message == "")
			report_configuration();

		if(number == LINK_COMMAND_CONFIGURE_SCANNER)
		{
			if(message == SCANNER_CONFIG_REGION) scope = AGENT_LIST_REGION;
			if(message == SCANNER_CONFIG_OWNED) scope = AGENT_LIST_PARCEL_OWNER;
			if(message == SCANNER_CONFIG_PARCEL) scope = AGENT_LIST_PARCEL;
		}
	}

	state_entry()
	{
		debug_prefix = "scanner";
		DEBUG = FALSE; // DEBUG_STYLE_LOCAL;

		llSetTimerEvent(TIMER_INTERVAL);
	}

	timer()
	{
		scan();
	}
}
