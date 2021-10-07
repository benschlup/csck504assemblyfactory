// CSCK504 Multi-agent systems group assignment: Team E
// 07 October 2021
// Contact: benjamin.schlup@schlup.com!start.

// Let's assume a gripper percept is not always available: let's retry
// (Background are limitations of the environment simulation.)
+?gripper(X,Y,A) : true
  <-?gripper(X,Y,A).
	
// The following position should be used to park the robotic arm outside
// the main assembly area or in a hovering position when waiting for new parts
waitingposition(270,720,90).
hoverposition(270,613,90).

+readyForAssembly : true
<- .print("Robotic arm agent: Restarting part positioning process!");
   !positionParts.

// Initial "hello" message, then embrace the goal to position parts
+!start : true
<- .print("Robotic arm agent: Hello!").
   
// Intentionally individual plans per part to make sure we process parts
// in a preferred sequence. A generic plan resulted in suboptimal 
// sequence, so that the welding robot could not start at the earliest
// possible time.

+!positionParts : binfull(Part) & Part<4 & not holding(Part) & (not lockedArea(2) | not lockedArea(1))
<- !!hoverArm;
   .print("Robotic arm agent: requesting access to assembly areas 1 and 2.");
   .my_name(Agent);
   .send(assemblyareaagent,achieve,lockAreaFor(Agent,2));
   .send(assemblyareaagent,achieve,lockAreaFor(Agent,1));
   .wait(200);
   !positionParts.
  
+!positionParts : binfull(Part) & Part>=4 & not holding(Part) & not lockedArea(1)
<- !!hoverArm;
   .print("Robotic arm agent: requesting access to assembly area 1.");
   .my_name(Agent);
   .send(assemblyareaagent,achieve,lockAreaFor(Agent,1));
   .wait(200);
   !positionParts.
   
+!positionParts : binfull(1) & not holding(1) & lockedArea(2)
<- !pickupAndpositionPart(1);
   !positionParts.

+!positionParts : binfull(2) & not holding(2) & lockedArea(2)
<- !pickupAndpositionPart(2);
   !positionParts.

+!positionParts : binfull(3) & not holding(3) & lockedArea(2)
<- !pickupAndpositionPart(3);
   !positionParts.

+!positionParts : binfull(4) & not holding(4) & lockedArea(1)
<- !pickupAndpositionPart(4);
   !positionParts.

+!positionParts : binfull(5) & not holding(5) & lockedArea(1)
<- !pickupAndpositionPart(5);
   !positionParts.

+!positionParts : binfull(6) & not holding(6) & lockedArea(1)
<- !pickupAndpositionPart(6);
   !positionParts.

// In case we are still missing any part(s) we retry 
+!positionParts : not (holding(1) & holding(2) & holding(3) &
                       holding(4) & holding(5) & holding(6))
<- !hoverArm;
   !positionParts.
	
// Otherwise, the positionParts process has completed
+!positionParts : true
<- !!parkArm.

// A plan to move towards a specific position and putting the gripper
// into a specified angle
+!moveTo(X,Y,Angle) : not gripper(X,Y,Angle)
  <- move_towards(X,Y,Angle);
     !moveTo(X,Y,Angle).

// We declare success when the gripper percept confirms arrival at the target position 
+!moveTo(X,Y,Angle) : gripper(X,Y,Angle).

// A combined plan to go pickup a part from a bin and position it in the
// holder. Thereafter, embrace the plan to park the arm.
+!pickupAndpositionPart(Part) : true 
<- !pickupPart(Part);
   .print("Robotic arm agent: positioning part ", Part, ".");
   !positionPart(Part).
   
// The sub-plan to actually pick up a part. Before doing so, we drop any
// potential cocurrent intention to park the robotic arm
+!pickupPart(Part) : true
<- .drop_intention(parkArm);
   .drop_intention(hoverArm);
   .print("Robotic arm agent: picking part from bin ", Part, ".");
   ?binPosition(Part,X1,Y1);
   !moveTo(X1,Y1,90);
   pick_part(Part).

// The sub-plan to actually position the part in a holder unless the holder
// confirms (via percept) it has fixed the part
+!positionPart(Part) : not holding(Part) // & lockedArea
<- ?partPosition(Part,X2,Y2,Angle);
   !moveTo(X2,Y2,Angle);
   .broadcast(tell,part_in_place(Part));
   !positionPart(Part).

// Now that the holder has confirmed the fixing of the part, the gripper can
// release the part
+!positionPart(Part) : holding(Part)
<- .print("Robotic arm agent: releasing part ", Part, ".");
   .broadcast(untell,part_in_place(Part));
   release_part;
   !awaitUnlockArea.
 
// Wait until assembly area is not locked any longer
+!awaitUnlockArea : lockedArea(_)
<- .print("Robotic arm agent: giving way to others.");
   .my_name(Agent);
   .send(assemblyareaagent,achieve,unlockAreaFor(Agent,1));
   .send(assemblyareaagent,achieve,unlockAreaFor(Agent,2));
   .wait(200);
   !awaitUnlockArea.
   
+!awaitUnlockArea : not lockedArea(Area).
   
// Position the arm in a hovering position to quickly reach a new part
+!hoverArm : true
<- ?hoverposition(X,Y,Angle);
   !hoverArm(X,Y,Angle).
   
+!hoverArm(X,Y,Angle) : not gripper(X,Y,Angle)
<- !moveTo(X,Y,Angle).

+!hoverArm(X,Y,Angle) : gripper(X,Y,Angle).

// Position the arm in a waiting position outside the main assembly area
+!parkArm : true
<- ?waitingposition(X,Y,Angle);
   !moveTo(X,Y,Angle).

