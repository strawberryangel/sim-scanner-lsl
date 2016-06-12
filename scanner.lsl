integer SLICE_SIZE = 20;
string BUNDLE_DELIMITER = "|";

scan()
{
	list agents = llGetAgentList(AGENT_LIST_PARCEL_OWNER, []);
	integer count = llGetListLength(agents);
	integer start = 0;
	integer stop;

	while(start < count)
	{
		stop = start + SLICE_SIZE - 1;
		if(stop >= count) stop = count-1;

		list slice = llList2List(agents, start, stop);
		string bundle = llDumpList2String(slice, BUNDLE_DELIMITER);
		llOwnerSay(bundle);

		start = stop + 1;
	}
}

default
{
	touch_end(integer total_number)
	{
		scan();
	}
}
