functor
import
   Player069Random
   Player069Rocketman
   Player069Kamikaze
   Player003Memory
   Player003BomberMan
   Player038Cartographer
   Player020Hunter
   Player014FullRandom
   Player014WellerMine
export
   playerGenerator:PlayerGenerator
define
   PlayerGenerator
in
   fun{PlayerGenerator Kind Color ID}
      case Kind
      of kamikaze then {Player069Kamikaze.portPlayer Color ID}
      [] rocketman then {Player069Rocketman.portPlayer Color ID}
      [] random then {Player069Random.portPlayer Color ID}
      
      % These are the players from the other groups with which we tested our code.
      %[] memory then {Player003Memory.portPlayer Color ID}
      %[] bomberman then {Player003BomberMan.portPlayer Color ID}
      %[] carto then {Player038Cartographer.portPlayer Color ID}
      %[] hunter then {Player020Hunter.portPlayer Color ID}
      %[] wellermine then {Player014WellerMine.portPlayer Color ID}
      end
   end
end
