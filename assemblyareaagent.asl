// CSCK504 Multi-agent systems group assignment: Team E
// 07 October 2021
// Contact: benjamin.schlup@schlup.com

// Initial intention
!maintenance_loop.

// Rule for complete holder release
holdersReleased(N) :- not holding(N) & (N = 1 | holdersReleased(N-1)). 
holdersReleased :- holdersReleased(6).

// Let's assume percepts are not always available: let's retry

+?gripper(X,Y,A) : true
  <-?gripper(X,Y,A).

+?welder(X,Y) : true
  <-?welder(X,Y).

+?mover(X,Y) : true
  <-?mover(X,Y).
  
// Main maintenance loop
+!maintenance_loop : true
<- .print("Assembly Area Agent: ready for assembling frame.");
   .broadcast(tell,readyForAssembly);
   !waitForUsage;
   .print("Assembly Area Agent: assembly area busy.");
   .broadcast(untell,readyForAssembly);
   !waitForFree(0,0,0);
   !maintenance_loop.

// Wait until an indication that the assembly process has started
+!waitForUsage : holdersReleased
<-!waitForUsage.
   
+!waitForUsage.
   
   
// Notify everyone when the area is not being used any longer
+!waitForFree(Wx,Gy,My) : not holdersReleased  | Wx < 1000  | Gy < 720 | My > 70
<- ?welder(Wx1,_);
   ?gripper(_,Gy1,_);
   ?mover(_,My1);
   !waitForFree(Wx1,Gy1,My1).
   
+!waitForFree(_,_,_).
   
// Reserve assembly area for an agent
@Lock [atomic]
+!lockAreaFor(Agent,Area): not lockedAreaFor(_,Area)
<- +lockedAreaFor(Agent,Area);
   lock_area(Area);
   .send(Agent,tell,lockedArea(Area)).
   
+!lockAreaFor(Agent,Area).

// Reserve assembly area for an agent
@Unlock [atomic]
+!unlockAreaFor(Agent,Area) : lockedAreaFor(Agent,Area)
<- -lockedAreaFor(Agent,Area);
   unlock_area(Area);
   .send(Agent,untell,lockedArea(Area)).
   
+!unlockAreaFor(Agent,Area) : true.   

