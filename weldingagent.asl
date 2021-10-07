// CSCK504 Multi-agent systems group assignment: Team E
// 07 October 2021
// Contact: benjamin.schlup@schlup.com

// Belief of a position where we can park the welding tool outside
// the main assembly area
waitingposition(1000,470).


// Let's assume a welder percept is not always available: let's retry
// (Background are limitations of the environment simulation.)
+?welder(X,Y) : true
  <-?welder(X,Y).

// Rules for parts that shall be welded together
jointPartsInPlace(1) :- holding(1) & holding(2) & holding(3).
jointPartsInPlace(2) :- holding(2) & holding(4).
jointPartsInPlace(3) :- holding(3) & holding(4) & holding(6).
jointPartsInPlace(4) :- holding(4) & holding(5).
jointPartsInPlace(5) :- holding(5) & holding(6).

// Rule for complete holder release
holdersReleased(N) :- not holding(N) & (N = 1 | holdersReleased(N-1)). 
holdersReleased :- holdersReleased(6).

// Rule for identifying completely welded frame
jointsDone(N) :- joint(N) & (N = 1 | joint(N-1)).
jointsDone :- jointsDone(5).

// Embrace initial plan
!main.

+!main : true
<- .print("Welding robot: waiting for new parts");
   !weldParts;
   !waitForFrameRemoval;
   !forgetJoints;
   !main.

// Plan to forget welded joints (note that a recursive version didn't work)
+!forgetJoints : true
<- -joint(1);
   -joint(2);
   -joint(3);
   -joint(4);
   -joint(5).
   
// In case we are getting a new percept that a holder has fixed a part,
// we check if we need to weld it. 
// If we need to move the welder to the assembly area, lock it first.
+!weldParts : jointPartsInPlace(1) & not joint(1) & not lockedArea(2)
<- .print("Welding robot: requesting access to assembly area 2.");
   .my_name(Agent);
   .send(assemblyareaagent,achieve,lockAreaFor(Agent,2));
   .send(assemblyareaagent,achieve,unlockAreaFor(Agent,1));
   .wait(200); // be careful to not request access too frequently
   !weldParts.

+!weldParts : Joint > 1 & jointPartsInPlace(Joint) & not joint(Joint) & (not lockedArea(1) | not lockedArea(2)) & not (jointPartsInPlace(1) & not joint(1))
<- .print("Welding robot: requesting access to assembly areas 1 and 2.");
   .my_name(Agent);
   .send(assemblyareaagent,achieve,lockAreaFor(Agent,1));
   .send(assemblyareaagent,achieve,lockAreaFor(Agent,2));
   .wait(200); // be careful to not request access too frequently
   !weldParts.
   
// Now that the area is locked, we move the welder to the joint position and 
// do our job.
+!weldParts : (Joint = 1 & jointPartsInPlace(Joint) & not joint(Joint) & lockedArea(2)) |
              (Joint > 1 & jointPartsInPlace(Joint) & not joint(Joint) & lockedArea(1) & lockedArea(2))
<- .print("Welding robot: welding joint ", Joint);
   .drop_intention(parkArm);
   ?jointPosition(Joint,X,Y);
   !moveTo(X,Y);
   weld;
   +joint(Joint);
   !!parkArm;
   !weldParts.
   
// Retry cycle if not all joints done 
+!weldParts : not jointsDone
<- .wait(200); // not retry to frequently
   !weldParts.

// Once we arrive here, the frame is complete
+!weldParts : true
<- .print("Finished, tell the mover agent!");
   .send(movingagent,achieve,removeFrame).

// Plan to wait for all holders being released, to know when the frame is moved away
+!waitForFrameRemoval : not holdersReleased
<- !waitForFrameRemoval.

+!waitForFrameRemoval : holdersReleased.

// Plan for moving the welding tool around 
+!moveTo(X,Y) : not welder(X,Y)
  <- move_towards(X,Y,0);
     !moveTo(X,Y).
	 
// We declare success when the welder percept confirms arrival at the target position 
+!moveTo(X,Y) : welder(X,Y).

// When the robot has no job, park the arm outside the main assembly area
+!parkArm : true
<- ?waitingposition(X,Y);
   !moveTo(X,Y);
   .print("Welding agent: giving way to others.");
   .my_name(Agent);
   .send(assemblyareaagent,achieve,unlockAreaFor(Agent,1));
   .send(assemblyareaagent,achieve,unlockAreaFor(Agent,2)).
