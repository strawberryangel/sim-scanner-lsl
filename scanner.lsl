#include "sim-scanner-lsl/lib.lsl"
	#include "sim-scanner-lsl/main.h"
		#include "lib/channels.lsl"
			#include "lib/debug.lsl"

				string VERSION = "1.4.0";

scan()
{
	list agents = llGetAgentList(AGENT_LIST_PARCEL_OWNER, []);
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
		{
			llMessageLinked(LINK_SET, LINK_COMMAND_REPORT_VERSION, SCRIPT_SCANNER + "|" + VERSION, NULL_KEY);
			return;
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
