/obj/machinery/atmospherics/binary/valve
	icon = 'icons/atmos/valve.dmi'
	icon_state = "map_valve0"

	name = "manual valve"
	desc = "A pipe valve."

	can_unwrench = 1

	var/open = 0

	req_one_access_txt = "24;10"

/obj/machinery/atmospherics/binary/valve/examine(mob/user)
	. = ..()
	. += "It is currently [open ? "open" : "closed"]."

/obj/machinery/atmospherics/binary/valve/open
	open = 1
	icon_state = "map_valve1"

/obj/machinery/atmospherics/binary/valve/update_icon(animation)
	..()

	if(animation)
		flick("valve[src.open][!src.open]",src)
	else
		icon_state = "valve[open]"

/obj/machinery/atmospherics/binary/valve/update_underlays()
	if(..())
		underlays.Cut()
		var/turf/T = get_turf(src)
		if(!istype(T))
			return
		add_underlay(T, node1, get_dir(src, node1))
		add_underlay(T, node2, get_dir(src, node2))

/obj/machinery/atmospherics/binary/valve/proc/open()
	open = 1
	update_icon()
	parent1.update = 0
	parent2.update = 0
	parent1.reconcile_air()
	investigate_log("was opened by [usr ? key_name_log(usr) : "a remote signal"]", INVESTIGATE_ATMOS)
	return

/obj/machinery/atmospherics/binary/valve/proc/close()
	open = 0
	update_icon()
	investigate_log("was closed by [usr ? key_name_log(usr) : "a remote signal"]", INVESTIGATE_ATMOS)
	return

/obj/machinery/atmospherics/binary/valve/attack_ai(mob/user)
	return

/obj/machinery/atmospherics/binary/valve/attack_ghost(mob/user)
	if(user.can_advanced_admin_interact())
		return attack_hand(user)

/obj/machinery/atmospherics/binary/valve/attack_hand(mob/user)
	add_fingerprint(usr)
	update_icon(1)
	sleep(10)
	if(open)
		close()
	else
		open()
	to_chat(user, "<span class='notice'>You [open ? "open" : "close"] [src].</span>")

/obj/machinery/atmospherics/binary/valve/digital		// can be controlled by AI
	name = "digital valve"
	desc = "A digitally controlled valve."
	icon = 'icons/atmos/digital_valve.dmi'

	frequency = ATMOS_VENTSCRUB
	var/id_tag = null

/obj/machinery/atmospherics/binary/valve/digital/Destroy()
	if(SSradio)
		SSradio.remove_object(src, frequency)
	radio_connection = null
	return ..()

/obj/machinery/atmospherics/binary/valve/digital/attack_ai(mob/user)
	if(isAI(user) && !user:add_heat(AI_NORMAL_ACTION_HEAT))
		return
	return attack_hand(user)

/obj/machinery/atmospherics/binary/valve/digital/attack_hand(mob/user)
	if(!powered())
		return
	if(!allowed(user) && !user.can_advanced_admin_interact())
		to_chat(user, "<span class='alert'>Access denied.</span>")
		return
	..()

/obj/machinery/atmospherics/binary/valve/digital/open
	open = 1
	icon_state = "map_valve1"

/obj/machinery/atmospherics/binary/valve/digital/power_change()
	var/old_stat = stat
	..()
	if(old_stat != stat)
		update_icon()

/obj/machinery/atmospherics/binary/valve/digital/update_icon()
	..()
	if(!powered())
		icon_state = "valve[open]nopower"

/obj/machinery/atmospherics/binary/valve/digital/atmos_init()
	..()
	if(frequency)
		set_frequency(frequency)

/obj/machinery/atmospherics/binary/valve/digital/receive_signal(datum/signal/signal)
	if(!signal.data["tag"] || (signal.data["tag"] != id_tag))
		return 0

	switch(signal.data["command"])
		if("valve_open")
			if(!open)
				open()

		if("valve_close")
			if(open)
				close()

		if("valve_toggle")
			if(open)
				close()
			else
				open()
		if("valve_set")
			if(signal.data["valve_set"] == 1)
				if(!open)
					open()
			else
				if(open)
					close()
