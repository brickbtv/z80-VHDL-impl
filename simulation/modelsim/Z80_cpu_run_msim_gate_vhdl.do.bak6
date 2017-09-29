transcript on
if {[file exists gate_work]} {
	vdel -lib gate_work -all
}
vlib gate_work
vmap work gate_work

vcom -93 -work work {Z80_cpu.vho}

vcom -93 -work work {D:/VHDL/Z80_cpu/simulation/modelsim/Z80_cpu_vhd_tst.vht}

vsim -t 1ps +transport_int_delays +transport_path_delays -sdftyp /Z80_cpu_vhd_tst=Z80_cpu_vhd.sdo -L cycloneii -L gate_work -L work -voptargs="+acc"  Z80_cpu_vhd_tst

add wave *
view structure
view signals
run 1 ms
