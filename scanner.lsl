#include "sim-scanner-lsl/main.h"
	#include "lib/debug.lsl"

		string VERSION = "1.3.0";

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

		#ifdef DEBUG
			llOwnerSay(bundle);
		#endif

			llMessageLinked(LINK_SET, LM_TRANSMITTER, bundle, NULL_KEY);

		start = stop + 1;
	}
}

default
{
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
	touch_end(integer total_number)
	{
		scan();
	}
}
