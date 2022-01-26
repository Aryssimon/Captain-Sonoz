functor
import
    Input
    OS
    System
export
   portPlayer:StartPlayer
define
    StartPlayer
    TreatStream
    RandomPosition
    Manhattan
    Abs
    RandomRow
    RandomColumn
    OkSquare
    Move
    ChargeItem
    FireItem
    FireMine
    RandomPositionForMine
    RandomPositionForMissile
    IsBlocked
    RandomMine
in
    fun{StartPlayer Color ID}
        Stream
        Port
    in
        {NewPort Stream Port}
        thread CurrPosition in
            {TreatStream Stream id(id:ID color:Color name:player069kamikaze) CurrPosition true Input.maxDamage 0 0 nil nil false false false}
        end
        Port
    end

    fun{Abs X}
        if X < 0 then ~X else X end
    end

    %%
    % Computes manhattan distance between the two <position> : D = |x1 − x2| + |y1 − y2|
    %%
    fun{Manhattan P1 P2}
        {Abs P1.x-P2.x}+{Abs P1.y-P2.y}
    end

    fun {RandomRow CurrPosition}
        Row
    in
        Row=({OS.rand} mod Input.nRow)+1
        if Row == CurrPosition.x then {RandomRow CurrPosition} else Row end
    end

    fun {RandomColumn CurrPosition}
        Column
    in
        Column=({OS.rand} mod Input.nColumn)+1
        if Column == CurrPosition.x then {RandomColumn CurrPosition} else Column end
    end

    proc {RandomPosition ?Position VisitedSquares}
        X Y RandPos
    in
        X = ({OS.rand} mod Input.nRow) + 1
        Y = ({OS.rand} mod Input.nColumn) + 1
        RandPos = pt(x:X y:Y)
        if {OkSquare RandPos VisitedSquares} then
            Position = RandPos
        else
            {RandomPosition ?Position VisitedSquares}
        end
    end

    % Check if Position is a Water square inside the map not already visited since last surface
    fun {OkSquare Position VisitedSquares}
        fun {IsWater Position}
            {List.nth {List.nth Input.map Position.x} Position.y} == 0
        end
        fun {IsInsideMap Position}
            Position.x >= 1 andthen Position.x =< Input.nRow andthen Position.y >= 1 andthen Position.y =< Input.nColumn
        end
        fun {IsNotVisitedSquare VisitedSquares Position}
            case VisitedSquares of nil then true
            [] Old|T andthen Position.x == Old.x andthen Position.y == Old.y then false
            else {IsNotVisitedSquare VisitedSquares.2 Position}
            end
        end
    in
        {IsInsideMap Position} andthen {IsWater Position} andthen {IsNotVisitedSquare VisitedSquares Position}
    end

    fun {IsBlocked Position VisitedSquares}
        PositionUp = pt(x:Position.x-1 y:Position.y)
        PositionDown = pt(x:Position.x+1 y:Position.y)
        PositionLeft = pt(x:Position.x y:Position.y-1)
        PositionRight = pt(x:Position.x y:Position.y+1)
        fun {Ok Position}
            {OkSquare Position VisitedSquares}
        end
    in
        if {Ok PositionUp} orelse {Ok PositionDown} orelse {Ok PositionLeft} orelse {Ok PositionRight} then
            false
        else
            true
        end
    end

    proc {Move ?Position ?Direction T Id CurrPosition LifePoints MineLoad DroneLoad VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}
        if {IsBlocked CurrPosition VisitedSquares} then
            Direction = surface
            Position = CurrPosition
            {TreatStream T Id Position true LifePoints MineLoad DroneLoad nil MinesList GoPlaceMine MinePlaced DroneOk}
        else Pos Dir in
            case {OS.rand} mod 4
            of 0 then
                Dir = north
                Pos = pt(x:CurrPosition.x-1 y:CurrPosition.y)
            [] 1 then
                Dir = south
                Pos = pt(x:CurrPosition.x+1 y:CurrPosition.y)
            [] 2 then
                Dir = west
                Pos = pt(x:CurrPosition.x y:CurrPosition.y-1)
            [] 3 then
                Dir = east
                Pos = pt(x:CurrPosition.x y:CurrPosition.y+1)
            end
            if {OkSquare Pos VisitedSquares} then
                Position = Pos
                Direction = Dir
                {TreatStream T Id Position false LifePoints MineLoad DroneLoad CurrPosition|VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}
            else
                {Move ?Position ?Direction T Id CurrPosition LifePoints MineLoad DroneLoad VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}
            end
        end
    end

    proc {ChargeItem ?KindItem T Id CurrPosition AtSurface LifePoints MineLoad DroneLoad VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}
        if GoPlaceMine orelse MinePlaced then
            if DroneLoad+1 mod Input.drone == 0 then
                KindItem = drone
            else
                KindItem = null
            end
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad DroneLoad+1 VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}
        else
            if MineLoad+1 mod Input.mine == 0 then
                KindItem = mine
            else
                KindItem = null
            end
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad+1 DroneLoad VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}
        end
    end

    % Returns a random mine from the list
    fun {RandomMine MinesList}
        RandomIndex = {OS.rand} mod {Length MinesList}
        fun {Loop List Index}
            if Index == 0 then List.1
            else {Loop List.2 Index-1}
            end
        end
    in
        {Loop MinesList RandomIndex}
    end

    proc {FireItem ?KindFire T Id CurrPosition AtSurface LifePoints MineLoad DroneLoad VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}
        if GoPlaceMine then
            if MineLoad >= Input.mine then MinePosition in
                MinePosition = CurrPosition
                KindFire = mine(MinePosition)
                {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad-Input.mine DroneLoad VisitedSquares MinePosition|MinesList true false DroneOk}
            else
                KindFire = null
                {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad DroneLoad VisitedSquares MinesList false true DroneOk}
            end
        elseif MineLoad >= 7*Input.mine then MinePosition in
            MinePosition = CurrPosition
            KindFire = mine(MinePosition)
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad-Input.mine DroneLoad VisitedSquares MinePosition|MinesList true false DroneOk}
        elseif DroneLoad >= Input.drone andthen MinePlaced andthen {Length MinesList} > 0 then
            if Input.nColumn > Input.nRow then
                KindFire = drone(column {RandomMine MinesList}.y)
            else
                KindFire = drone(row {RandomMine MinesList}.x)
            end
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad DroneLoad-Input.drone VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}
        else
            KindFire = null
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad DroneLoad VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}
        end
    end

    proc {FireMine ?Mine T Id CurrPosition AtSurface LifePoints MineLoad DroneLoad VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}
        fun {GetLast List}
            case List of H|nil then H
            [] H|T then {GetLast T}
            end
        end
        fun {RemoveLast List}
            case List of H|nil then nil
            [] H|T then H|{RemoveLast T}
            end
        end
    in
        if MinePlaced andthen DroneOk then
            if {List.length MinesList} > 0 then
                Mine = {GetLast MinesList}
                {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad DroneLoad VisitedSquares {RemoveLast MinesList}  GoPlaceMine MinePlaced DroneOk}
            else
                Mine = null
                {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad DroneLoad VisitedSquares MinesList GoPlaceMine false false}
            end
        else
            Mine = null
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad DroneLoad VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}
        end
    end

    proc{TreatStream Stream Id CurrPosition AtSurface LifePoints MineLoad DroneLoad VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}
        case Stream
        of nil then skip
        [] initPosition(?ID ?Position)|T then
            ID=Id
            {RandomPosition ?Position VisitedSquares}
            {TreatStream T Id Position AtSurface LifePoints MineLoad DroneLoad nil MinesList GoPlaceMine MinePlaced DroneOk}

        [] move(?ID ?Position ?Direction)|T then
            if LifePoints =< 0 then
                ID = null
                Position = null
                Direction = null
                {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad DroneLoad VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}
            else
                ID=Id
                {Move ?Position ?Direction T Id CurrPosition LifePoints MineLoad DroneLoad VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}
            end

        [] dive|T then
            {TreatStream T Id CurrPosition false LifePoints MineLoad DroneLoad nil MinesList GoPlaceMine MinePlaced DroneOk}

        [] chargeItem(?ID ?KindItem)|T then
            if LifePoints =< 0 then
                ID = null
                KindItem = null
                {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad DroneLoad VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}
            else
                ID=Id
                {ChargeItem ?KindItem T Id CurrPosition AtSurface LifePoints MineLoad DroneLoad VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}
            end
        [] fireItem(?ID ?KindFire)|T then
            if LifePoints =< 0 then
                ID = null
                KindFire = null
                {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad DroneLoad VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}
            else
                ID=Id
                {FireItem ?KindFire T Id CurrPosition AtSurface LifePoints MineLoad DroneLoad VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}
            end

        [] fireMine(?ID ?Mine)|T then
            if LifePoints =< 0 then
                ID = null
                Mine = null
                {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad DroneLoad VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}
            else
                ID=Id
                {FireMine ?Mine T Id CurrPosition AtSurface LifePoints MineLoad DroneLoad VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}
            end

        [] isDead(?Answer)|T then
            Answer = LifePoints =< 0
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad DroneLoad VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}

        [] sayMove(ID Direction)|T then
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad DroneLoad VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}

        [] saySurface(ID)|T then
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad DroneLoad VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}

        [] sayCharge(ID KindItem)|T then
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad DroneLoad VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}

        [] sayMinePlaced(ID)|T then
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad DroneLoad VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}

        [] sayMissileExplode(ID Position ?Message)|T then Distance LifeLeft DmgTaken in
            if LifePoints =< 0 then
                Message = null
                LifeLeft = 0
            else
                Distance = {Manhattan CurrPosition Position}

                if Distance == 1 then
                    LifeLeft=LifePoints-1
                    DmgTaken=1
                elseif Distance == 0 then
                    LifeLeft=LifePoints-2
                    DmgTaken=2
                else
                    DmgTaken=0
                    LifeLeft=LifePoints
                end
                if LifeLeft =< 0 then
                    Message=sayDeath(Id)
                elseif DmgTaken == 0 then
                    Message=null
                else
                    Message=sayDamageTaken(Id DmgTaken LifeLeft)
                end
            end
            {TreatStream T Id CurrPosition AtSurface LifeLeft MineLoad DroneLoad VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}

        [] sayMineExplode(ID Position ?Message)|T then Distance LifeLeft DmgTaken in
            if LifePoints =< 0 then
                Message = null
                LifeLeft = 0
            else
                Distance = {Manhattan CurrPosition Position}

                if Distance == 1 then
                    LifeLeft=LifePoints-1
                    DmgTaken=1
                elseif Distance == 0 then
                    LifeLeft=LifePoints-2
                    DmgTaken=2
                else
                    DmgTaken=0
                    LifeLeft=LifePoints
                end
                if LifeLeft =< 0 then
                    Message=sayDeath(Id)
                elseif DmgTaken == 0 then
                    Message=null
                else
                    Message=sayDamageTaken(Id DmgTaken LifeLeft)
                end
            end
            {TreatStream T Id CurrPosition AtSurface LifeLeft MineLoad DroneLoad VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}

        [] sayPassingDrone(Drone ?ID ?Answer)|T then
            if LifePoints =< 0 then ID=null else ID=Id end
            case Drone
            of drone(row X) then Answer = CurrPosition.x == X
            [] drone(column Y) then Answer = CurrPosition.y == Y
            end
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad DroneLoad VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}

        [] sayAnswerDrone(Drone ID Answer)|T then
            if Answer andthen ID \= Id then
                {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad DroneLoad VisitedSquares MinesList GoPlaceMine MinePlaced true}
            else
                {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad DroneLoad VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}
            end

        [] sayPassingSonar(?ID ?Answer)|T then Truth X Y in
            if LifePoints =< 0 then ID = null else ID=Id end
            Truth = {OS.rand} mod 2
            if Truth == 0 then
                X = CurrPosition.x
                Y = {RandomColumn CurrPosition}
            else
                X = {RandomRow CurrPosition}
                Y = CurrPosition.y
            end
            Answer = pt(x:X y:Y)
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad DroneLoad VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}

        [] sayAnswerSonar(ID Answer)|T then
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad DroneLoad VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}
        [] sayDeath(ID)|T then
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad DroneLoad VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}
        [] sayDamageTaken(ID Damage LifeLeft)|T then
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad DroneLoad VisitedSquares MinesList GoPlaceMine MinePlaced DroneOk}
        end
    end
end
