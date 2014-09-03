
var/global/datum/spacelift_controller/spacelift_controller


/datum/spacelift_controller
	var/list/shuttles	//maps shuttle tags to shuttle datums, so that they can be looked up.
	var/list/process_shuttles	//simple list of shuttles, for processing

/datum/spacelift_controller/proc/process()
	//process ferry shuttles
	for (var/datum/spacelift/lift in process_lifts)
		if (lift.process_state)
			lift.process()


/datum/spacelift_controller/New()
	lifts = list()
	process_lifts = list()

	var/datum/spacelift/lift
	// Public shuttles
	lift = new()
	lift.location = 1
	lift.warmup_time = 10
	lift.area_offsite = locate(/area/spacelift/space)
	lift.area_station = locate(/area/spacelift/planet)
	lift.docking_controller_tag = "space_lift"
	lift.dock_target_station = "space_lift_planet"
	lift.dock_target_offsite = "space_lift_space"
	lifts["Main"] = lift
	process_lifts += lift


//This is called by gameticker after all the machines and radio frequencies have been properly initialized
/datum/spacelift_controller/proc/setup_lift_docks()
	var/datum/spacelift/lift
	var/datum/spacelift/lift/multidock/multidock
	var/list/dock_controller_map = list()	//so we only have to iterate once through each list

	//multidock shuttles
	var/list/dock_controller_map_station = list()
	var/list/dock_controller_map_offsite = list()

	for (var/lift_tag in lifts)
		lift = lifts[lift_tag]
		if (lift.docking_controller_tag)
			dock_controller_map[lift.docking_controller_tag] = shuttle
		if (istype(lift, /datum/lift/ferry/multidock))
			multidock = lift
			dock_controller_map_station[multidock.docking_controller_tag_station] = multidock
			dock_controller_map_offsite[multidock.docking_controller_tag_offsite] = multidock

	//search for the controllers, if we have one.
	if (dock_controller_map.len)
		for (var/obj/machinery/embedded_controller/radio/C in machines)	//only radio controllers are supported at the moment
			if (istype(C.program, /datum/computer/file/embedded_program/docking))
				if (C.id_tag in dock_controller_map)
					shuttle = dock_controller_map[C.id_tag]
					shuttle.docking_controller = C.program
					dock_controller_map -= C.id_tag


	//sanity check
	if (dock_controller_map.len || dock_controller_map_station.len || dock_controller_map_offsite.len)
		var/dat = ""
		for (var/dock_tag in dock_controller_map + dock_controller_map_station + dock_controller_map_offsite)
			dat += "\"[dock_tag]\", "
		world << "\red \b warning: lift with docking tags [dat] could not find their controllers!"

	//makes all shuttles docked to something at round start go into the docked state
	for (var/lift_tag in lifts)
		lift = lifts[lift_tag]
		lift.dock()
