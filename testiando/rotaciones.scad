


for (rot_x =[0:20:360])

rotate([rot_x,0,0])
translate([0,0,50])
cylinder(50,5,5);

color("#ff0000")
translate([-50,0,0])
for (rot_x =[0:20:360])
rotate([rot_x,0,0])
translate([0,50,0])
cylinder(50,5,5);

color("#ff00ff")
translate([-100,0,0])
for (rot_x =[0:20:360])
rotate([rot_x,0,0])
translate([0,0,0])
cylinder(50,5,5);

translate([150,0,0])
for (rot_y =[0:20:360])
rotate([0,rot_y,0])
translate([0,0,50])
cylinder(50,5,5);

color("#00ff00")
translate([-150,0,-150])
for (rot_z =[0:20:360])
rotate([0,0,rot_z])
translate([50,0,0])
cylinder(50,5,5);

translate([100,0,-150])
for (rot_z =[0:20:360])
rotate([0,0,rot_z])
translate([0,-50,0])
rotate([90,0,0])
cylinder(50,5,5);