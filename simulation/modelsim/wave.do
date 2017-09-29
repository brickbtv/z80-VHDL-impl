onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group Counters /z80_cpu_vhd_tst/i1/SP
add wave -noupdate -expand -group Counters -radix decimal -childformat {{/z80_cpu_vhd_tst/i1/PC(15) -radix decimal} {/z80_cpu_vhd_tst/i1/PC(14) -radix decimal} {/z80_cpu_vhd_tst/i1/PC(13) -radix decimal} {/z80_cpu_vhd_tst/i1/PC(12) -radix decimal} {/z80_cpu_vhd_tst/i1/PC(11) -radix decimal} {/z80_cpu_vhd_tst/i1/PC(10) -radix decimal} {/z80_cpu_vhd_tst/i1/PC(9) -radix decimal} {/z80_cpu_vhd_tst/i1/PC(8) -radix decimal} {/z80_cpu_vhd_tst/i1/PC(7) -radix decimal} {/z80_cpu_vhd_tst/i1/PC(6) -radix decimal} {/z80_cpu_vhd_tst/i1/PC(5) -radix decimal} {/z80_cpu_vhd_tst/i1/PC(4) -radix decimal} {/z80_cpu_vhd_tst/i1/PC(3) -radix decimal} {/z80_cpu_vhd_tst/i1/PC(2) -radix decimal} {/z80_cpu_vhd_tst/i1/PC(1) -radix decimal} {/z80_cpu_vhd_tst/i1/PC(0) -radix decimal}} -subitemconfig {/z80_cpu_vhd_tst/i1/PC(15) {-height 15 -radix decimal} /z80_cpu_vhd_tst/i1/PC(14) {-height 15 -radix decimal} /z80_cpu_vhd_tst/i1/PC(13) {-height 15 -radix decimal} /z80_cpu_vhd_tst/i1/PC(12) {-height 15 -radix decimal} /z80_cpu_vhd_tst/i1/PC(11) {-height 15 -radix decimal} /z80_cpu_vhd_tst/i1/PC(10) {-height 15 -radix decimal} /z80_cpu_vhd_tst/i1/PC(9) {-height 15 -radix decimal} /z80_cpu_vhd_tst/i1/PC(8) {-height 15 -radix decimal} /z80_cpu_vhd_tst/i1/PC(7) {-height 15 -radix decimal} /z80_cpu_vhd_tst/i1/PC(6) {-height 15 -radix decimal} /z80_cpu_vhd_tst/i1/PC(5) {-height 15 -radix decimal} /z80_cpu_vhd_tst/i1/PC(4) {-height 15 -radix decimal} /z80_cpu_vhd_tst/i1/PC(3) {-height 15 -radix decimal} /z80_cpu_vhd_tst/i1/PC(2) {-height 15 -radix decimal} /z80_cpu_vhd_tst/i1/PC(1) {-height 15 -radix decimal} /z80_cpu_vhd_tst/i1/PC(0) {-height 15 -radix decimal}} /z80_cpu_vhd_tst/i1/PC
add wave -noupdate -radix decimal /z80_cpu_vhd_tst/ADDR
add wave -noupdate /z80_cpu_vhd_tst/CLK
add wave -noupdate /z80_cpu_vhd_tst/DATA
add wave -noupdate /z80_cpu_vhd_tst/i1/DATA_OUT
add wave -noupdate /z80_cpu_vhd_tst/WR
add wave -noupdate /z80_cpu_vhd_tst/RESET
add wave -noupdate -expand -group {Base Reg} /z80_cpu_vhd_tst/i1/A
add wave -noupdate -expand -group {Base Reg} /z80_cpu_vhd_tst/i1/B
add wave -noupdate -expand -group {Base Reg} /z80_cpu_vhd_tst/i1/C
add wave -noupdate -expand -group {Base Reg} /z80_cpu_vhd_tst/i1/D
add wave -noupdate -expand -group {Base Reg} /z80_cpu_vhd_tst/i1/E
add wave -noupdate -expand -group {Base Reg} /z80_cpu_vhd_tst/i1/H
add wave -noupdate -expand -group {Base Reg} /z80_cpu_vhd_tst/i1/L
add wave -noupdate -expand -group {Index Reg} /z80_cpu_vhd_tst/i1/IX
add wave -noupdate -expand -group {Index Reg} /z80_cpu_vhd_tst/i1/IY
add wave -noupdate -expand -group Memory -expand -group Start /z80_cpu_vhd_tst/i1/Mem1/ram(16)
add wave -noupdate -expand -group Memory -expand -group Start /z80_cpu_vhd_tst/i1/Mem1/ram(15)
add wave -noupdate -expand -group Memory -expand -group Start /z80_cpu_vhd_tst/i1/Mem1/ram(14)
add wave -noupdate -expand -group Memory -expand -group Start /z80_cpu_vhd_tst/i1/Mem1/ram(13)
add wave -noupdate -expand -group Memory -expand -group Start /z80_cpu_vhd_tst/i1/Mem1/ram(12)
add wave -noupdate -expand -group Memory -expand -group Start /z80_cpu_vhd_tst/i1/Mem1/ram(11)
add wave -noupdate -expand -group Memory -expand -group Start /z80_cpu_vhd_tst/i1/Mem1/ram(10)
add wave -noupdate -expand -group Memory -expand -group Start /z80_cpu_vhd_tst/i1/Mem1/ram(9)
add wave -noupdate -expand -group Memory -expand -group Start /z80_cpu_vhd_tst/i1/Mem1/ram(8)
add wave -noupdate -expand -group Memory -expand -group Start /z80_cpu_vhd_tst/i1/Mem1/ram(7)
add wave -noupdate -expand -group Memory -expand -group Start /z80_cpu_vhd_tst/i1/Mem1/ram(6)
add wave -noupdate -expand -group Memory -expand -group Start /z80_cpu_vhd_tst/i1/Mem1/ram(5)
add wave -noupdate -expand -group Memory -expand -group Start /z80_cpu_vhd_tst/i1/Mem1/ram(4)
add wave -noupdate -expand -group Memory -expand -group Start /z80_cpu_vhd_tst/i1/Mem1/ram(3)
add wave -noupdate -expand -group Memory -expand -group Start /z80_cpu_vhd_tst/i1/Mem1/ram(2)
add wave -noupdate -expand -group Memory -expand -group Start /z80_cpu_vhd_tst/i1/Mem1/ram(1)
add wave -noupdate -expand -group Memory -expand -group Start /z80_cpu_vhd_tst/i1/Mem1/ram(0)
add wave -noupdate -expand -group Memory -expand -group Stack /z80_cpu_vhd_tst/i1/Mem1/ram(127)
add wave -noupdate -expand -group Memory -expand -group Stack /z80_cpu_vhd_tst/i1/Mem1/ram(126)
add wave -noupdate -expand -group Memory -expand -group Stack /z80_cpu_vhd_tst/i1/Mem1/ram(125)
add wave -noupdate -expand -group Memory -expand -group Stack /z80_cpu_vhd_tst/i1/Mem1/ram(124)
add wave -noupdate -expand -group Memory -expand -group Stack /z80_cpu_vhd_tst/i1/Mem1/ram(123)
add wave -noupdate -expand -group Memory -expand -group Stack /z80_cpu_vhd_tst/i1/Mem1/ram(122)
add wave -noupdate -expand -group Memory -expand -group Stack /z80_cpu_vhd_tst/i1/Mem1/ram(121)
add wave -noupdate -expand -group Memory -expand -group Stack /z80_cpu_vhd_tst/i1/Mem1/ram(120)
add wave -noupdate -expand -group Memory -expand -group Stack /z80_cpu_vhd_tst/i1/Mem1/ram(119)
add wave -noupdate -expand -group Memory -expand -group Stack /z80_cpu_vhd_tst/i1/Mem1/ram(118)
add wave -noupdate -expand -group Memory -expand -group Stack /z80_cpu_vhd_tst/i1/Mem1/ram(117)
add wave -noupdate -expand -group Memory -expand -group Stack /z80_cpu_vhd_tst/i1/Mem1/ram(116)
add wave -noupdate -expand -group Memory -expand -group Stack /z80_cpu_vhd_tst/i1/Mem1/ram(115)
add wave -noupdate -expand -group Memory -expand -group Stack /z80_cpu_vhd_tst/i1/Mem1/ram(114)
add wave -noupdate -expand -group Memory -expand -group Stack /z80_cpu_vhd_tst/i1/Mem1/ram(113)
add wave -noupdate -expand -group Memory -expand -group Stack /z80_cpu_vhd_tst/i1/Mem1/ram(112)
add wave -noupdate -expand -group Memory -expand -group Stack /z80_cpu_vhd_tst/i1/Mem1/ram(111)
add wave -noupdate -expand -group Memory -expand -group Stack /z80_cpu_vhd_tst/i1/Mem1/ram(110)
add wave -noupdate -expand -group ALU /z80_cpu_vhd_tst/i1/Alu1/OP8_A
add wave -noupdate -expand -group ALU /z80_cpu_vhd_tst/i1/Alu1/OP8_B
add wave -noupdate -expand -group ALU /z80_cpu_vhd_tst/i1/Alu1/CODE
add wave -noupdate -expand -group ALU /z80_cpu_vhd_tst/i1/Alu1/RES8
add wave -noupdate -expand -group ALU /z80_cpu_vhd_tst/i1/Alu1/FLAGS
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {134468 ps} 0} {{Edit Cursor} {302531 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 251
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {36791 ps} {524380 ps}
