set val(chan)       Channel/WirelessChannel
set val(prop1)      Propagation/TwoRayGround
set val(prop2)      Propagation/FreeSpace
set val(netif)      Phy/WirelessPhy
set val(mac)        Mac/802_11
set val(ifq)        Queue/DropTail/PriQueue
set val(ll)         LL
set val(ant)        Antenna/OmniAntenna
set val(x)              1500   ;# X dimension of the topography
set val(y)              1000   ;# Y dimension of the topography
set val(ifqlen)         50            ;# max packet in ifq
set val(seed)           0.0
set val(adhocRouting)   DSR
set val(nn)             50             ;# how many nodes are simulated
#set val(cp)             "./cbr-3-test" 
#set val(sc)             "./scen-3-test" 
set val(stop)           900.0           ;# simulation time

set ns [new Simulator]
set topo [new Topography]
set tracefd	[open wireless1-out.tr w]
set namtrace    [open wireless1-out.nam w]

$ns trace-all $tracefd
$ns namtrace-all-wireless $namtrace $val(x) $val(y)
$topo load_flatgrid $val(x) $val(y)
set god [create-god $val(nn)]
set chan_1 [new $val(chan)]


$ns node-config -adhocRouting $val(adhocRouting) \
                 -llType $val(ll) \
                 -macType $val(mac) \
                 -ifqType $val(ifq) \
                 -ifqLen $val(ifqlen) \
                 -antType $val(ant) \
                 -propType $val(prop1) \
		 -propType $val(prop2) \
                 -phyType $val(netif) \
                 -channelType $val(chan) \
		 -topoInstance $topo \
		 -agentTrace ON \
                 -routerTrace ON \
		 -movementTrace ON \
                 -macTrace OFF \


for {set i 0} {$i < $val(nn) } {incr i} {
	set node($i) [$ns node]	
	$node($i) random-motion 0		;# disable random motion
}

for {set i 0} {$i < $val(nn)} {incr i} {
	$ns initial_node_pos $node($i) 20
}

set node(0) [$ns node]
set node(1) [$ns node]



$node(0) set X_ 5.0
$node(0) set Y_ 2.0
$node(0) set Z_ 0.0

$node(1) set X_ 8.0
$node(1) set Y_ 5.0
$node(1) set Z_ 0.0

$ns at 3.0 "$node(1) setdest 50.0 40.0 25.0"
$ns at 3.0 "$node(0) setdest 48.0 38.0 5.0"


$ns at 20.0 "$node(0) setdest 490.0 480.0 30.0" 



set sink0 [new Agent/LossMonitor]
set sink1 [new Agent/LossMonitor]
$ns attach-agent $node(0) $sink0
$ns attach-agent $node(1) $sink1

set tcp [new Agent/TCP]
$tcp set class_ 2
set sink [new Agent/TCPSink]
$ns attach-agent $node(0) $tcp
$ns attach-agent $node(1) $sink
$ns connect $tcp $sink

proc finish {} {
    global ns namtrace
    $ns flush-trace
    close $namtrace 
}
proc attach-CBR-traffic { node sink size interval } {
   #Get an instance of the simulator
   set ns [Simulator instance]
   #Create a CBR  agent and attach it to the node
   set cbr [new Agent/CBR]
   $ns attach-agent $node $cbr
   $cbr set packetSize_ $size
   $cbr set interval_ $interval

   #Attach CBR source to sink;
   $ns connect $cbr $sink
   return $cbr
  }

set cbr0 [attach-CBR-traffic $node(0) $sink1 1000 .015]
$ns at 1.0 "$cbr0 start"

puts "Starting Simulation..."
$ns at 30.0 "finish"
$ns run

