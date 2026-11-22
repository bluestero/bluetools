-- unikit: the laptop only sends audio to Bluetooth devices, never receives it as a speaker or headset.
-- Earbuds that also advertise "Audio Source" otherwise open a backwards music link on reconnect,
-- and music mode (a2dp-sink) never shows up.
bluez_monitor.properties["bluez5.roles"] = "[ a2dp_source hfp_ag hsp_ag ]"
