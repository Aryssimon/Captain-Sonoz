functor
import
    Input
    OS
    System
export
   portPlayer:StartPlayer
define
    IsWater
    IsInsideMap
    IsNotVisitedSquare
    StartPlayer
    TreatStream
    Manhattan
    Abs
    OkSquare
    OkSquareBis
    Move
    ChargeItem
    FireItem
    FireMine
    GetMinCreatedItem
    InitEnemyLifePoints
    GetEnemyMinLifePoints
    DirectionToTargetPos
    IsBlocked
    RandomDirection
    CheckDirections
    RandomPosition
    RandomPositionBis
    InitEnemyPositions
    RandomID
in
    fun{StartPlayer Color ID}
        Stream
        Port
        EnemyLifePoints
        EnemyPositions
        TargetID
    in
        EnemyLifePoints = {InitEnemyLifePoints enemylifepoints() 1}
        EnemyPositions = {InitEnemyPositions enemypositions() 1}
        {RandomID TargetID ID}
        {NewPort Stream Port}
        thread CurrPosition in
            {TreatStream Stream id(id:ID color:Color name:player069rocketman) CurrPosition true Input.maxDamage 0
              target(id:TargetID pos:EnemyPositions.TargetID)
              null
              armory(mineLoad:0 missileLoad:0 droneLoad:0 sonarLoad:0 mineCreated:0 missileCreated:0 droneCreated:0 sonarCreated:0)
              EnemyPositions
              EnemyLifePoints
              nil}
        end
        Port
    end

    /*
    * Gives Random position inside map that is not an island and that has not been visited
    */
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

    /*
    * Gives a random ID beside ourself
    */
    proc{RandomID ?RandID ID}
        Rand = ({OS.rand} mod Input.nbPlayers)+1
    in
        if Rand \= ID then
            RandID = Rand
        else
            {RandomID ?RandID ID}
        end
    end

    /*
    * Gives Random position inside map that is not an island
    */
    proc {RandomPositionBis ?Position}
        X Y RandPos
    in
        X = ({OS.rand} mod Input.nRow) + 1
        Y = ({OS.rand} mod Input.nColumn) + 1
        RandPos = pt(x:X y:Y)
        if {OkSquareBis RandPos} then
            Position = RandPos
        else
            {RandomPositionBis ?Position}
        end
    end

    fun{InitEnemyLifePoints EnemyLifePoints ID}
        if ID == Input.nbPlayers+1 then EnemyLifePoints
        else
            {InitEnemyLifePoints {Adjoin EnemyLifePoints new(ID:Input.maxDamage)} ID+1}
        end
    end

    fun{InitEnemyPositions EnemyPositions ID}
        if ID == Input.nbPlayers+1 then EnemyPositions
        else Position in
            {RandomPositionBis Position}
            {InitEnemyPositions {Adjoin EnemyPositions new(ID:Position)} ID+1}
        end
    end

    /*
    * get enemy id with least LifePoints beside ourself
    */
    fun{GetEnemyMinLifePoints EnemyLifePoints Min MinID ID MyID}
        if ID == Input.nbPlayers+1 then MinID
        else
            if ID \= MyID then
                if EnemyLifePoints.ID \= null andthen EnemyLifePoints.ID < Min then
                    {GetEnemyMinLifePoints EnemyLifePoints EnemyLifePoints.ID ID ID+1 MyID}
                else
                    {GetEnemyMinLifePoints EnemyLifePoints Min MinID ID+1 MyID}
                end
            else
                {GetEnemyMinLifePoints EnemyLifePoints Min MinID ID+1 MyID}
            end
        end
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

    % Check if Position is a Water square inside the map not already visited since last surface
    fun {OkSquare Position VisitedSquares}
        if {IsInsideMap Position} andthen {IsWater Position} andthen {IsNotVisitedSquare VisitedSquares Position} then
            true
        else
            false
        end
    end

    % Check if Position is a Water square inside the map
    fun {OkSquareBis Position}
        if {IsInsideMap Position} andthen {IsWater Position} then
            true
        else
            false
        end
    end

    fun {IsBlocked Position VisitedSquares}
        PositionUp = pt(x:Position.x-1 y:Position.y)
        PositionDown = pt(x:Position.x+1 y:Position.y)
        PositionLeft = pt(x:Position.x y:Position.y-1)
        PositionRight = pt(x:Position.x y:Position.y+1)
    in
        if {OkSquare PositionUp VisitedSquares} then
            false
        elseif {OkSquare PositionDown VisitedSquares} then
            false
        elseif {OkSquare PositionLeft VisitedSquares} then
            false
        elseif {OkSquare PositionRight VisitedSquares} then
            false
        else
            true
        end
    end


    /*
    * Check if the 4 directions in order of parameters are valid squares and return the first (direction position) valid
    */
    fun{CheckDirections Dir1 Pos1 Dir2 Pos2 Dir3 Pos3 Dir4 Pos4 VisitedSquares}
        if {OkSquare Pos1 VisitedSquares} then dp(dir:Dir1 pos:Pos1)
        elseif {OkSquare Pos2 VisitedSquares} then dp(dir:Dir2 pos:Pos2)
        elseif {OkSquare Pos3 VisitedSquares} then dp(dir:Dir3 pos:Pos3)
        else dp(dir:Dir4 pos:Pos4)
        end
    end

    /*
    * Determine which direction to go to get to target position
    */
    fun{DirectionToTargetPos PosFrom PosTo}
        if PosTo.x < PosFrom.x andthen PosTo.y == PosFrom.y then south
        elseif PosTo.x > PosFrom.x andthen PosTo.y == PosFrom.y then north
        elseif PosTo.y < PosFrom.y andthen PosTo.x == PosFrom.x then west
        elseif PosTo.y > PosFrom.y andthen PosTo.x == PosFrom.x then east

        elseif PosTo.x < PosFrom.x andthen PosTo.y < PosFrom.y then southorwest
        elseif PosTo.x > PosFrom.x andthen PosTo.y < PosFrom.y then northorwest
        elseif PosTo.y > PosFrom.y andthen PosTo.x < PosFrom.x then southoreast
        else northoreast
        end
    end


    /*
    * Give a random position
    */
    fun{RandomDirection}
        Rand = {OS.rand} mod 4
    in
        case Rand of 0 then west
        [] 1 then east
        [] 2 then north
        [] 3 then south
        end
    end

    /*
    * Determine how the submarine moves
    */
    proc {Move ?Position ?Direction T Id CurrPosition LifePoints DestroyEnemyAuthorization Target TargetPosition Armory EnemyPositions EnemyLifePoints VisitedSquares}
        East = pt(x:CurrPosition.x y:CurrPosition.y+1)
        West = pt(x:CurrPosition.x y:CurrPosition.y-1)
        North = pt(x:CurrPosition.x-1 y:CurrPosition.y)
        South = pt(x:CurrPosition.x+1 y:CurrPosition.y)
        Pos Dir Resp
    in
        if {IsBlocked CurrPosition VisitedSquares} then %surface if completely blocked
            Position=CurrPosition Direction=surface
            {TreatStream T Id Position true LifePoints DestroyEnemyAuthorization Target TargetPosition Armory EnemyPositions EnemyLifePoints nil}
        else
            case TargetPosition of null then %move randomly if no TargetPosition (after launching a missile)
                Dir = {RandomDirection}
                case Dir
                of north then
                    Pos = North
                [] south then
                    Pos = South
                [] west then
                    Pos = West
                [] east then
                    Pos = East
                end
                if {OkSquare Pos VisitedSquares} then
                    Position = Pos
                    Direction = Dir
                    {TreatStream T Id Position true LifePoints DestroyEnemyAuthorization Target TargetPosition Armory EnemyPositions EnemyLifePoints CurrPosition|VisitedSquares}
                else
                    {Move ?Position ?Direction T Id CurrPosition LifePoints DestroyEnemyAuthorization Target TargetPosition Armory EnemyPositions EnemyLifePoints VisitedSquares}
                end
            [] pt(x:X y:Y) then %move towards the target position if there is one
                Dir = {DirectionToTargetPos CurrPosition TargetPosition}
                case Dir
                of north then
                    Resp = {CheckDirections north North east East west West south South VisitedSquares}
                    Direction = Resp.dir
                    Position = Resp.pos
                [] south then
                    Resp = {CheckDirections south South east East west West north North VisitedSquares}
                    Direction = Resp.dir
                    Position = Resp.pos
                [] east then
                    Resp = {CheckDirections east East north North south South west West VisitedSquares}
                    Direction = Resp.dir
                    Position = Resp.pos
                [] west then
                    Resp = {CheckDirections west West north North south South east East VisitedSquares}
                    Direction = Resp.dir
                    Position = Resp.pos
                [] southoreast then
                    Resp = {CheckDirections south South east East west West north North VisitedSquares}
                    Direction = Resp.dir
                    Position = Resp.pos
                [] southorwest then
                    Resp = {CheckDirections west West south South east East north North VisitedSquares}
                    Direction = Resp.dir
                    Position = Resp.pos
                [] northoreast then
                    Resp = {CheckDirections east East north North south South west West VisitedSquares}
                    Direction = Resp.dir
                    Position = Resp.pos
                [] northorwest then
                    Resp = {CheckDirections north North west West south South east East VisitedSquares}
                    Direction = Resp.dir
                    Position = Resp.pos
                end
                {TreatStream T Id Position true LifePoints DestroyEnemyAuthorization Target TargetPosition Armory EnemyPositions EnemyLifePoints CurrPosition|VisitedSquares}
            end
        end
    end


    /*
    * Get the item with minimum count in the armory between missiles,drones,sonars
    */
    fun {GetMinCreatedItem Armory Min MinIndex Index}
        case Index
        of drone then
            if Armory.droneCreated < Min then
                {GetMinCreatedItem Armory Armory.droneCreated drone sonar}
            else
                {GetMinCreatedItem Armory Min MinIndex sonar}
            end
        []sonar then
            if Armory.sonarCreated < Min then
                sonar
            else
                MinIndex
            end
        end
    end

    /*
    * The player creates items in order : 1 Missile - 1 Drone - 1 Sonar
    */
    proc {ChargeItem ?KindItem T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization Target TargetPosition Armory EnemyPositions EnemyLifePoints VisitedSquares}
        UpdatedArmory
        ItemToCreate
    in
        ItemToCreate = {GetMinCreatedItem Armory Armory.missileCreated missile drone}
        case ItemToCreate
        of missile then Result NewMissileLoad in
            NewMissileLoad = Armory.missileLoad + 1
            Result = NewMissileLoad mod Input.missile == 0
            if NewMissileLoad mod Input.missile == 0 then Tmp in
                KindItem = missile
                Tmp = {Adjoin Armory new(missileLoad:0)}
                UpdatedArmory = {Adjoin Tmp new(missileCreated:Armory.missileCreated+1)}
                {TreatStream T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization Target TargetPosition UpdatedArmory EnemyPositions EnemyLifePoints VisitedSquares}
            else
                KindItem = null
                UpdatedArmory = {Adjoin Armory new(missileLoad:Armory.missileLoad+1)}
                {TreatStream T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization Target TargetPosition UpdatedArmory EnemyPositions EnemyLifePoints VisitedSquares}
            end
        []drone then NewDroneLoad in
            NewDroneLoad = Armory.droneLoad + 1
            if NewDroneLoad mod Input.drone == 0 then Tmp in
                KindItem = drone
                Tmp = {Adjoin Armory new(droneLoad:0)}
                UpdatedArmory = {Adjoin Tmp new(droneCreated:Armory.droneCreated+1)}
                {TreatStream T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization Target TargetPosition UpdatedArmory EnemyPositions EnemyLifePoints VisitedSquares}
            else
                KindItem = null
                UpdatedArmory = {Adjoin Armory new(droneLoad:Armory.droneLoad+1)}
                {TreatStream T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization Target TargetPosition UpdatedArmory EnemyPositions EnemyLifePoints VisitedSquares}
            end
        []sonar then NewSonarLoad in
            NewSonarLoad = Armory.sonarLoad + 1
            if NewSonarLoad mod Input.sonar == 0 then Tmp in
                KindItem = sonar
                Tmp = {Adjoin Armory new(sonarLoad:0)}
                UpdatedArmory = {Adjoin Tmp new(sonarCreated:Armory.sonarCreated+1)}
                {TreatStream T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization Target TargetPosition UpdatedArmory EnemyPositions EnemyLifePoints VisitedSquares}
            else
                KindItem = null
                UpdatedArmory = {Adjoin Armory new(sonarLoad:Armory.sonarLoad+1)}
                {TreatStream T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization Target TargetPosition UpdatedArmory EnemyPositions EnemyLifePoints VisitedSquares}
            end
        end
    end

    proc {FireItem ?KindFire T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization Target TargetPosition Armory EnemyPositions EnemyLifePoints VisitedSquares}
        UpdatedArmory
    in

        if Armory.missileCreated >= 1 andthen Armory.droneCreated >= 1 andthen Armory.sonarCreated >= 1 andthen DestroyEnemyAuthorization == 0 then
            KindFire = sonar
            UpdatedArmory = {Adjoin Armory new(sonarLoad:Armory.sonarLoad-1)}
            {TreatStream T Id CurrPosition AtSurface LifePoints 1 Target TargetPosition UpdatedArmory EnemyPositions EnemyLifePoints VisitedSquares}

        elseif DestroyEnemyAuthorization == 1 then UpdatedTarget TargetID in

            TargetID = Target.id
            UpdatedTarget = {Adjoin Target new(pos:EnemyPositions.TargetID)}
            KindFire = drone(row UpdatedTarget.pos.x)
            UpdatedArmory = {Adjoin Armory new(droneLoad:Armory.droneLoad-1)}
            {TreatStream T Id CurrPosition AtSurface LifePoints 2 UpdatedTarget UpdatedTarget.pos UpdatedArmory EnemyPositions EnemyLifePoints VisitedSquares}

        elseif DestroyEnemyAuthorization == 2 then ManhattanDistance in
            ManhattanDistance = {Manhattan TargetPosition CurrPosition}
            if ManhattanDistance >= Input.minDistanceMissile andthen ManhattanDistance =< Input.maxDistanceMissile then
                KindFire = missile(TargetPosition)
                UpdatedArmory = {Adjoin Armory new(missileLoad:Armory.missileLoad-1)}
                {TreatStream T Id CurrPosition AtSurface LifePoints 0 Target null UpdatedArmory EnemyPositions EnemyLifePoints VisitedSquares}
            else
                KindFire = null
                UpdatedArmory = Armory
                {TreatStream T Id CurrPosition AtSurface LifePoints 2 Target TargetPosition UpdatedArmory EnemyPositions EnemyLifePoints VisitedSquares}
            end

        else
            KindFire = null
            UpdatedArmory = Armory
            {TreatStream T Id CurrPosition AtSurface LifePoints 0 Target TargetPosition UpdatedArmory EnemyPositions EnemyLifePoints VisitedSquares}
        end
    end


    proc{TreatStream Stream Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization Target TargetPosition Armory EnemyPositions EnemyLifePoints VisitedSquares}
        case Stream
        of nil then skip
        [] initPosition(?ID ?Position)|T then
            ID=Id
            {RandomPosition ?Position VisitedSquares}
            {TreatStream T Id Position AtSurface LifePoints DestroyEnemyAuthorization Target TargetPosition Armory EnemyPositions EnemyLifePoints nil}

        [] move(?ID ?Position ?Direction)|T then
            if LifePoints =< 0 then
                ID = null
                Position = null
                Direction = null
                {TreatStream T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization Target TargetPosition Armory EnemyPositions EnemyLifePoints VisitedSquares}
            else
                ID=Id
                {Move ?Position ?Direction T Id CurrPosition LifePoints DestroyEnemyAuthorization Target TargetPosition Armory EnemyPositions EnemyLifePoints VisitedSquares}
            end

        [] dive|T then
            {TreatStream T Id CurrPosition false LifePoints DestroyEnemyAuthorization Target TargetPosition Armory EnemyPositions EnemyLifePoints nil}

        [] chargeItem(?ID ?KindItem)|T then
            if LifePoints =< 0 then
                ID = null
                KindItem = null
                {TreatStream T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization Target TargetPosition Armory EnemyPositions EnemyLifePoints VisitedSquares}
            else
                ID=Id
                {ChargeItem ?KindItem T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization Target TargetPosition Armory EnemyPositions EnemyLifePoints VisitedSquares}
            end
        [] fireItem(?ID ?KindFire)|T then
            if LifePoints =< 0 then
                ID = null
                KindFire = null
                {TreatStream T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization Target TargetPosition Armory EnemyPositions EnemyLifePoints VisitedSquares}
            else
                ID=Id
                {FireItem ?KindFire T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization Target TargetPosition Armory EnemyPositions EnemyLifePoints VisitedSquares}
            end

        [] fireMine(?ID ?Mine)|T then
            if LifePoints =< 0 then
                ID = null
                Mine = null
                {TreatStream T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization Target TargetPosition Armory EnemyPositions EnemyLifePoints VisitedSquares}
            else
                ID=Id
                Mine=null
                {TreatStream T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization Target TargetPosition Armory EnemyPositions EnemyLifePoints VisitedSquares}
            end

        [] isDead(?Answer)|T then
            Answer = LifePoints =< 0
            {TreatStream T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization Target TargetPosition Armory EnemyPositions EnemyLifePoints VisitedSquares}

        [] sayMove(ID Direction)|T then UpdatedEnemyPositions UpdatedTarget IntID East West North South in
            IntID = ID.id
            East = pt(x:EnemyPositions.IntID.x y:EnemyPositions.IntID.y+1)
            West = pt(x:EnemyPositions.IntID.x y:EnemyPositions.IntID.y-1)
            North = pt(x:EnemyPositions.IntID.x-1 y:EnemyPositions.IntID.y)
            South = pt(x:EnemyPositions.IntID.x+1 y:EnemyPositions.IntID.y)
            case Direction
            of surface then {TreatStream T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization Target TargetPosition Armory EnemyPositions EnemyLifePoints VisitedSquares}
            [] east then
                if {OkSquareBis East} then
                    UpdatedEnemyPositions = {Adjoin EnemyPositions new(IntID:East)}
                    if IntID == Target.id then
                        UpdatedTarget = {Adjoin Target new(pos:East)}
                    else
                        UpdatedTarget = Target
                    end
                    {TreatStream T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization UpdatedTarget UpdatedTarget.pos Armory UpdatedEnemyPositions EnemyLifePoints VisitedSquares}
                else
                    UpdatedEnemyPositions = EnemyPositions
                    UpdatedTarget = Target
                    {TreatStream T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization UpdatedTarget UpdatedTarget.pos Armory UpdatedEnemyPositions EnemyLifePoints VisitedSquares}
                end
            [] west then
                if {OkSquareBis West} then
                    UpdatedEnemyPositions = {Adjoin EnemyPositions new(IntID:West)}
                    if IntID == Target.id then
                        UpdatedTarget = {Adjoin Target new(pos:West)}
                    else
                        UpdatedTarget = Target
                    end
                    {TreatStream T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization UpdatedTarget UpdatedTarget.pos Armory UpdatedEnemyPositions EnemyLifePoints VisitedSquares}
                else
                    UpdatedEnemyPositions = EnemyPositions
                    UpdatedTarget = Target
                    {TreatStream T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization UpdatedTarget UpdatedTarget.pos Armory UpdatedEnemyPositions EnemyLifePoints VisitedSquares}
                end
            [] north then
                if {OkSquareBis North} then
                    UpdatedEnemyPositions = {Adjoin EnemyPositions new(IntID:North)}
                    if IntID == Target.id then
                        UpdatedTarget = {Adjoin Target new(pos:North)}
                    else
                        UpdatedTarget = Target
                    end
                    {TreatStream T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization UpdatedTarget UpdatedTarget.pos Armory UpdatedEnemyPositions EnemyLifePoints VisitedSquares}
                else
                    UpdatedEnemyPositions = EnemyPositions
                    UpdatedTarget = Target
                    {TreatStream T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization UpdatedTarget UpdatedTarget.pos Armory UpdatedEnemyPositions EnemyLifePoints VisitedSquares}
                end
            [] south then
                if {OkSquareBis South} then
                    UpdatedEnemyPositions = {Adjoin EnemyPositions new(IntID:South)}
                    if IntID == Target.id then
                        UpdatedTarget = {Adjoin Target new(pos:South)}
                    else
                        UpdatedTarget = Target
                    end
                    {TreatStream T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization UpdatedTarget UpdatedTarget.pos Armory UpdatedEnemyPositions EnemyLifePoints VisitedSquares}
                else
                    UpdatedEnemyPositions = EnemyPositions
                    UpdatedTarget = Target
                    {TreatStream T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization UpdatedTarget UpdatedTarget.pos Armory UpdatedEnemyPositions EnemyLifePoints VisitedSquares}
                end
            end

        [] saySurface(ID)|T then
            {TreatStream T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization Target TargetPosition Armory EnemyPositions EnemyLifePoints VisitedSquares}

        [] sayCharge(ID KindItem)|T then
            {TreatStream T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization Target TargetPosition Armory EnemyPositions EnemyLifePoints VisitedSquares}

        [] sayMinePlaced(ID)|T then
            {TreatStream T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization Target TargetPosition Armory EnemyPositions EnemyLifePoints VisitedSquares}

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
            {TreatStream T Id CurrPosition AtSurface LifeLeft DestroyEnemyAuthorization Target TargetPosition Armory EnemyPositions EnemyLifePoints VisitedSquares}

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
            {TreatStream T Id CurrPosition AtSurface LifeLeft DestroyEnemyAuthorization Target TargetPosition Armory EnemyPositions EnemyLifePoints VisitedSquares}

        [] sayPassingDrone(Drone ?ID ?Answer)|T then
            if LifePoints =< 0 then ID=null else ID=Id end
            case Drone
            of drone(row X) then Answer = CurrPosition.x == X
            [] drone(column Y) then Answer = CurrPosition.y == Y
            end
            {TreatStream T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization Target TargetPosition Armory EnemyPositions EnemyLifePoints VisitedSquares}

        [] sayAnswerDrone(Drone ID Answer)|T then IntID UpdatedTarget in
            IntID = ID.id
            if Answer == true then %x is true and y is false
                if IntID == Target.id then
                    UpdatedTarget = {Adjoin Target new(pos:pt(x:Target.pos.x y:Input.nColumn div 2))}
                else
                    UpdatedTarget = Target
                end
            else %y is true and x is false
                if IntID == Target.id then
                    UpdatedTarget = {Adjoin Target new(pos:pt(x:Input.nRow y:Target.pos.y))}
                else
                    UpdatedTarget = Target
                end
            end
            {TreatStream T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization UpdatedTarget UpdatedTarget.pos Armory EnemyPositions EnemyLifePoints VisitedSquares}

        [] sayPassingSonar(?ID ?Answer)|T then X Y in
            if LifePoints =< 0 then ID = null else ID=Id end
            X = CurrPosition.x
            if CurrPosition.y =< Input.nColumn div 2 then
                Y = Input.nColumn
            else
                Y = 1
            end
            Answer = pt(x:X y:Y)
            {TreatStream T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization Target TargetPosition Armory EnemyPositions EnemyLifePoints VisitedSquares}

        [] sayAnswerSonar(ID Answer)|T then UpdatedEnemyPositions LowestEnemy UpdatedTarget IntID in
            IntID = ID.id
            UpdatedEnemyPositions = {Adjoin EnemyPositions new(IntID:Answer)}
            LowestEnemy = {GetEnemyMinLifePoints EnemyLifePoints Input.maxDamage+1 0 1 Id.id}
            UpdatedTarget = {Adjoin Target new(id:LowestEnemy)}
            {TreatStream T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization UpdatedTarget TargetPosition Armory UpdatedEnemyPositions EnemyLifePoints VisitedSquares}

        [] sayDeath(ID)|T then UpdatedEnemyPositions UpdatedEnemyLifePoints IntID LowestEnemy UpdatedTarget1 UpdatedTarget2 in
            IntID = ID.id
            UpdatedEnemyPositions = {Adjoin EnemyPositions new(IntID:null)}
            UpdatedEnemyLifePoints = {Adjoin EnemyLifePoints new(IntID:null)}
            LowestEnemy = {GetEnemyMinLifePoints UpdatedEnemyLifePoints Input.maxDamage+1 0 1 Id.id}
            if IntID == Target.id andthen LowestEnemy > 0 then
                UpdatedTarget1 = {Adjoin Target new(id:LowestEnemy)}
                UpdatedTarget2 = {Adjoin UpdatedTarget1 new(pos:UpdatedEnemyPositions.LowestEnemy)}
            else
                UpdatedTarget2 = Target
            end
            {TreatStream T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization UpdatedTarget2 TargetPosition Armory UpdatedEnemyPositions UpdatedEnemyLifePoints VisitedSquares}

        [] sayDamageTaken(ID Damage LifeLeft)|T then UpdatedEnemyLifePoints IntID in
            IntID = ID.id
            UpdatedEnemyLifePoints = {Adjoin EnemyLifePoints new(IntID:LifeLeft)}
            {TreatStream T Id CurrPosition AtSurface LifePoints DestroyEnemyAuthorization Target TargetPosition Armory EnemyPositions UpdatedEnemyLifePoints VisitedSquares}
        end
    end
end
