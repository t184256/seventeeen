/*
color("black") translate([0, 0, 0])
  linear_extrude(height = 1.2)
    import (file="out/outlines/pcb_perimeter.dxf", $fn=64);
*/
color("green") translate([0, 0, 0])
  linear_extrude(height = 1.2)
    import (file="out/outlines/silhouette.dxf", $fn=64);
color("blue") translate([0, 0, 1.2])
  linear_extrude(height = 2.8)
    import (file="out/outlines/switches_rounded.dxf", $fn=64);
color("grey") translate([0, 0, 4])
  linear_extrude(height = 3)
    import (file="out/outlines/keycaps_rounded.dxf", $fn=64);
color("pink") translate([0, 0, 0])
  linear_extrude(height = 1.2)
    import (file="out/outlines/mounting.dxf", $fn=64);
color("brown") translate([0, 0, -1.85])
  linear_extrude(height = 1.85)
    import (file="out/outlines/underside_approx.dxf", $fn=64);