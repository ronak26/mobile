
set val(chan) Channel/WirelessChannel ;# channel type
set val(prop) Propagation/TwoRayGround ;# radio-propagation model
set val(netif) Phy/WirelessPhy ;# network interface type
set val(mac) Mac/802_11 ;# MAC type
#set val(ifq) Queue/DropTail/PriQueue ;# interface queue type
set val(ll) LL ;# link layer type
set val(ant) Antenna/OmniAntenna ;# antenna model
set val(ifqlen) 1000 ;# max packet in ifq
set val(rp) DSR ;# routing protocol
#set val(seed) 1.0 ;#
if { $val(rp) == "DSR" } {
    set val(ifq) CMUPriQueue
} else {
    set val(ifq) Queue/DropTail/PriQueue
}
set val(nn) 50 ;# number of mobilenodes
set val(x) 1500 ;# X dimension of the topography
set val(y) 1000 ;# Y dimension of the topography
set val(stop) 900.0 ;# simulation time
#set val(path) /home/acharya/ns-allinone-2.35/ns-2.35
set val(cp) "./cbr-25-conf";
set val(sc) "./scen-25-conf1";
Agent/Null set sport_ 0
Agent/Null set dport_ 0
Agent/CBR set sport_ 0
Agent/CBR set dport_ 0

Antenna/OmniAntenna set X_ 0
Antenna/OmniAntenna set Y_ 0
Antenna/OmniAntenna set Z_ 2.5
Antenna/OmniAntenna set Gt_ 1.0
Antenna/OmniAntenna set Gr_ 1.0
set nominal_range 250.0
set configured_range -1.0
set configured_raw_bitrate -1.0
#Phy/WirelessPhy set bandwidth_ 11e6
#Mac/802_11 set basicRate_ 0
#Mac/802_11 set dataRate_ 0
#Mac/802_11 set bandwidth_ 11e6 ;
#Mac/802_11 set PLCPDataRate_ 11e6;
set ns_ [new Simulator]
set tracefd [open conf-out-tdsr.tr w]
$ns_ trace-all $tracefd
#$ns_ use-newtrace
# set the new channel interface.
#set chan [new $val(chan)]
#Open the nam file
set namtrace [open confout.nam w]
$ns_ namtrace-all-wireless $namtrace $val(x) $val(y)
#Set up topography object to keep track of movement of nodes
set topo [new Topography]
#Provide topography object with coordinates
$topo load_flatgrid $val(x) $val(y)
proc finish {} {
    global ns f f0 f1 f2 f3 namtrace
    #$ns_ flush-trace
    close $namtrace   
#close $f0
#    close $f1
#close $f2
#    close $f3
exec nam -r 5m confout.nam       
    # exec xgraph proj_out0.tr proj_out1.tr 
    # proj_out2.tr proj_out3.tr 
    # &
exit 0
}
create-god $val(nn)
$ns_ node-config -adhocRouting $val(rp) \
    -llType $val(ll) \
    -macType $val(mac) \
    -ifqType $val(ifq) \
    -ifqLen $val(ifqlen) \
    -antType $val(ant) \
    -propType $val(prop) \
    -phyType $val(netif) \
    -channelType $val(chan)\
    -topoInstance $topo \
    -agentTrace ON \
    -routerTrace OFF \
    -macTrace OFF \
    -movementTrace ON
#-channel $chan
for {set i 0} {$i < $val(nn) } {incr i} {
    puts "i: $i"
    set node_($i) [$ns_ node]
    $node_($i) random-motion 0 ;# disable random motion
}
puts "Loading connection pattern..."
source $val(cp)
puts "Loading scenario file..."
source $val(sc)
for {set i 0} {$i < $val(nn)} {incr i} {
    $ns_ initial_node_pos $node_($i) 50
}
for {set i 0} {$i < $val(nn) } {incr i} {
    $ns_ at $val(stop).0 "$node_($i) reset";
}


set sink0 [new Agent/LossMonitor]
set sink1 [new Agent/LossMonitor]
set sink2 [new Agent/LossMonitor]
set sink3 [new Agent/LossMonitor]
set sink4 [new Agent/LossMonitor]
set sink5 [new Agent/LossMonitor]
$ns_ attach-agent $node_(0) $sink0
$ns_ attach-agent $node_(1) $sink1
$ns_ attach-agent $node_(2) $sink2
$ns_ attach-agent $node_(3) $sink3
$ns_ attach-agent $node_(4) $sink4
$ns_ attach-agent $node_(5) $sink5

#$ns attach-agent $sink2 $sink3
set tcp0 [new Agent/TCP]
$ns_ attach-agent $node_(0) $tcp0
set tcp1 [new Agent/TCP]
$ns_ attach-agent $node_(1) $tcp1
set tcp2 [new Agent/TCP]
$ns_ attach-agent $node_(2) $tcp2
set tcp3 [new Agent/TCP]
$ns_ attach-agent $node_(3) $tcp3
set tcp4 [new Agent/TCP]
$ns_ attach-agent $node_(4) $tcp4
set tcp5 [new Agent/TCP]
$ns_ attach-agent $node_(5) $tcp5


proc attach-CBR-traffic { node sink size interval } {
   #Get an instance of the simulator
   set ns_ [Simulator instance]
   #Create a CBR  agent and attach it to the node
   set cbr [new Agent/CBR]
   $ns_ attach-agent $node $cbr
   $cbr set packetSize_ $size
   $cbr set interval_ $interval

   #Attach CBR source to sink;
   $ns_ connect $cbr $sink
   return $cbr
  }

set cbr0 [attach-CBR-traffic $node_(0) $sink5 1000 .015]



#$ns_ at $val(stop).0002 "puts \"NS EXITING...\" ; $ns_ halt"
puts $tracefd "Confidant Wrote this!"
puts $tracefd "M 0.0 nn $val(nn) x $val(x) y $val(y) rp $val(rp)"
#puts $tracefd "M 0.0 sc $val(sc) cp $val(cp) seed $val(seed)"
puts $tracefd "M 0.0 prop $val(prop) ant $val(ant)"



$ns_ at 1.0 "$cbr0 start"
$ns_ at 10.0 "finish"
puts "Starting Simulation..."
$ns_ run
