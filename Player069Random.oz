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
in
    fun{StartPlayer Color ID}
        Stream
        Port
    in
        {NewPort Stream Port}
        thread CurrPosition in
            {TreatStream Stream id(id:ID color:Color name:player069random) CurrPosition true Input.maxDamage 0 0 0 0 nil nil}
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
        fun {IsNotVisitedSquare VisitedSquares Position}
            case VisitedSquares of nil then true
            [] Old|T andthen Position.x == Old.x andthen Position.y == Old.y then false
            else {IsNotVisitedSquare VisitedSquares.2 Position}
            end
        end
    in
        if Position.x >= 1 andthen Position.x =< Input.nRow andthen Position.y >= 1 andthen Position.y =< Input.nColumn then
            if {List.nth {List.nth Input.map Position.x} Position.y} == 0 andthen {IsNotVisitedSquare VisitedSquares Position} then
                true
            else
                false
            end
        else
            false
        end
    end

    fun {RandomPositionForMissile CurrPosition}
        MissilePosition
        ManhattanDistance
    in
        {RandomPosition ?MissilePosition nil}
        ManhattanDistance = {Manhattan MissilePosition CurrPosition}
        if ManhattanDistance >= Input.minDistanceMissile andthen ManhattanDistance =< Input.maxDistanceMissile then
            MissilePosition
        else
            {RandomPositionForMissile CurrPosition}
        end
    end

    fun {RandomPositionForMine CurrPosition}
        MinePosition
        ManhattanDistance
    in
        {RandomPosition ?MinePosition nil}
        ManhattanDistance = {Manhattan MinePosition CurrPosition}
        if ManhattanDistance >= Input.minDistanceMine andthen ManhattanDistance =< Input.maxDistanceMine then
            MinePosition
        else
            {RandomPositionForMine CurrPosition}
        end
    end

    proc {Move ?Position ?Direction T Id CurrPosition LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}
        Pos Dir
    in
        case {OS.rand} mod 5
        of 0 then
            Dir = surface
            Pos = CurrPosition
        [] 1 then
            Dir = north
            Pos = pt(x:CurrPosition.x-1 y:CurrPosition.y)
        [] 2 then
            Dir = south
            Pos = pt(x:CurrPosition.x+1 y:CurrPosition.y)
        [] 3 then
            Dir = west
            Pos = pt(x:CurrPosition.x y:CurrPosition.y-1)
        [] 4 then
            Dir = east
            Pos = pt(x:CurrPosition.x y:CurrPosition.y+1)
        end
        if Dir == surface then
            Direction = Dir
            Position = Pos
            {TreatStream T Id Position true LifePoints MineLoad MissileLoad DroneLoad SonarLoad nil MinesList}
        elseif {OkSquare Pos VisitedSquares} then
            Position = Pos
            Direction = Dir
            {TreatStream T Id Position false LifePoints MineLoad MissileLoad DroneLoad SonarLoad CurrPosition|VisitedSquares MinesList}
        else
            {Move ?Position ?Direction T Id CurrPosition LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}
        end
    end

    proc {ChargeItem ?KindItem T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}
        case {OS.rand} mod 4
        of 0 then % Mine
            if MineLoad+1 mod Input.mine == 0 then
                KindItem = mine
            else
                KindItem = null
            end
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad+1 MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}
        [] 1 then % Missile
            if MissileLoad+1 mod Input.missile == 0 then
                KindItem = missile
            else
                KindItem = null
            end
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad+1 DroneLoad SonarLoad VisitedSquares MinesList}
        [] 2 then % Drone
            if DroneLoad+1 mod Input.drone == 0 then
                KindItem = drone
            else
                KindItem = null
            end
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad+1 SonarLoad VisitedSquares MinesList}
        [] 3 then % Sonar
            if SonarLoad+1 mod Input.sonar == 0 then
                KindItem = sonar
            else
                KindItem = null
            end
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad+1 VisitedSquares MinesList}
        end
    end

    proc {FireItem ?KindFire T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}
        if MineLoad < Input.mine andthen MissileLoad < Input.missile andthen DroneLoad < Input.drone andthen SonarLoad < Input.sonar then
            KindFire = null
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}
        else
            case {OS.rand} mod 4
            of 0 then % Mine
                if MineLoad >= Input.mine then MinePosition in
                    MinePosition = {RandomPositionForMine CurrPosition}
                    KindFire = mine(MinePosition)
                    {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad-Input.mine MissileLoad DroneLoad SonarLoad VisitedSquares MinePosition|MinesList}
                else
                    {FireItem ?KindFire T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}
                end
            [] 1 then % Missile
                if MissileLoad >= Input.missile then
                    KindFire = missile({RandomPositionForMissile CurrPosition})
                    {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad-Input.missile DroneLoad SonarLoad VisitedSquares MinesList}
                else
                    {FireItem ?KindFire T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}
                end

            [] 2 then % Drone
                if DroneLoad >= Input.drone then
                    KindFire = drone(row Input.nRow div 2)
                    {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad-Input.drone SonarLoad VisitedSquares MinesList}
                else
                    {FireItem ?KindFire T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}
                end
            [] 3 then % Sonar
                if SonarLoad >= Input.sonar then
                    KindFire = sonar
                    {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad-Input.sonar VisitedSquares MinesList}
                else
                    {FireItem ?KindFire T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}
                end
            end
        end
    end

    proc {FireMine ?Mine T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}
        MakeItExplode = {OS.rand} mod 10 % 1 out of 10 -- Explode if == 1
    in
        if MakeItExplode == 1 andthen {List.length MinesList} > 0 then
            % Dummy : explode the first one
            Mine = MinesList.1
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList.2}

        else
            Mine = null
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}
        end
    end


    proc{TreatStream Stream Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList} %% TODO: you may add as many argument as needed
        case Stream
        of nil then skip
        [] initPosition(?ID ?Position)|T then
            ID=Id
            {RandomPosition ?Position VisitedSquares}
            {TreatStream T Id Position AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad nil MinesList}

        [] move(?ID ?Position ?Direction)|T then
            if LifePoints =< 0 then
                ID = null
                Position = null
                Direction = null
                {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}
            else
                ID=Id
                {Move ?Position ?Direction T Id CurrPosition LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}
            end

        [] dive|T then
            {TreatStream T Id CurrPosition false LifePoints MineLoad MissileLoad DroneLoad SonarLoad nil MinesList}

        [] chargeItem(?ID ?KindItem)|T then
            if LifePoints =< 0 then
                ID = null
                KindItem = null
                {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}
            else
                ID=Id
                {ChargeItem ?KindItem T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}
            end
        [] fireItem(?ID ?KindFire)|T then
            if LifePoints =< 0 then
                ID = null
                KindFire = null
                {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}
            else
                ID=Id
                {FireItem ?KindFire T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}
            end

        [] fireMine(?ID ?Mine)|T then
            if LifePoints =< 0 then
                ID = null
                Mine = null
                {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}
            else
                ID=Id
                {FireMine ?Mine T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}
            end

        [] isDead(?Answer)|T then
            Answer = LifePoints =< 0
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}

        [] sayMove(ID Direction)|T then
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}

        [] saySurface(ID)|T then
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}

        [] sayCharge(ID KindItem)|T then
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}

        [] sayMinePlaced(ID)|T then
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}

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
            {TreatStream T Id CurrPosition AtSurface LifeLeft MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}

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
            {TreatStream T Id CurrPosition AtSurface LifeLeft MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}

        [] sayPassingDrone(Drone ?ID ?Answer)|T then
            if LifePoints =< 0 then ID=null else ID=Id end
            case Drone
            of drone(row X) then Answer = CurrPosition.x == X
            [] drone(column Y) then Answer = CurrPosition.y == Y
            end
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}

        [] sayAnswerDrone(Drone ID Answer)|T then
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}

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
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}

        [] sayAnswerSonar(ID Answer)|T then
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}
        [] sayDeath(ID)|T then
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}
        [] sayDamageTaken(ID Damage LifeLeft)|T then
            {TreatStream T Id CurrPosition AtSurface LifePoints MineLoad MissileLoad DroneLoad SonarLoad VisitedSquares MinesList}
        end
    end
end
