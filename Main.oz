functor
import
    GUI
    Input
    PlayerManager
    System
    OS
define
    GuiPort
    InitPlayers
    PlayersRecord
    InitPosition
    InitSurfaces
    InitSurfacesRecord
    Broadcast
    TurnByTurn
    Simultaneous
    BroadcastMineExplode
    BroadcastMissileExplode
    BroadcastPassingDrone
    BroadcastPassingSonar
    StartSimultaneousPlayers
    SimulateThinking
    SimultaneousAlivePlayers
    TerminatePorts
in
    fun {InitPlayers Kinds Colors ID PlayersRecord}
        if ID == Input.nbPlayers+1 then PlayersRecord
        else
            {InitPlayers Kinds.2 Colors.2 ID+1 {Adjoin record(ID:{PlayerManager.playerGenerator Kinds.1 Colors.1 ID}) PlayersRecord}}
        end
    end

    proc {InitPosition Count}
        if Count =< Input.nbPlayers then ID Position in
            {Send PlayersRecord.Count initPosition(ID Position)}
            {Send GuiPort initPlayer(ID Position)}
            {InitPosition Count+1}
        end
    end

    fun {InitSurfaces ID SurfacesRecord}
        if ID == Input.nbPlayers+1 then SurfacesRecord
        else
            {InitSurfaces ID+1 {Adjoin record(ID:1) SurfacesRecord}}
        end
    end

    proc {SimulateThinking}
        Difference = Input.thinkMax - Input.thinkMin
        Min = Input.thinkMin
    in
        if Difference > 0 andthen Min >= 0 then
            {Delay Min + ({OS.rand} mod Difference)}
        elseif Min > 0 then
            {Delay Min}
        end
    end

    /*
    % Broadcast a Msg to all players
    */
    proc {Broadcast Msg}
        proc {BroadcastLoop Msg PlayerID}
            if PlayerID =< Input.nbPlayers then
                {Send PlayersRecord.PlayerID Msg}
                {BroadcastLoop Msg PlayerID+1}
            end
        end
    in
        {BroadcastLoop Msg 1}
    end


    /*
    * Broadcast sayMissileExplode message then broadcast deaths and damageTaken messages and update GUI
    */
    fun {BroadcastMissileExplode ID Position}
        fun {BroadcastLoop PlayerID ID Position PlayersDead}
            if PlayerID =< Input.nbPlayers then Message in
                {Send PlayersRecord.PlayerID sayMissileExplode(ID Position ?Message)}
                case Message
                of sayDeath(Id) then
                    {Broadcast sayDeath(Id)}
                    {Send GuiPort removePlayer(Id)}
                    {BroadcastLoop PlayerID+1 ID Position PlayersDead+1}
                [] sayDamageTaken(Id Damage LifeLeft) then
                    {Broadcast sayDamageTaken(Id Damage LifeLeft)}
                    {Send GuiPort lifeUpdate(Id LifeLeft)}
                    {BroadcastLoop PlayerID+1 ID Position PlayersDead}
                else {BroadcastLoop PlayerID+1 ID Position PlayersDead}
                end
            else
                PlayersDead
            end
        end
    in
        {BroadcastLoop 1 ID Position 0}
    end


    /*
    * Broadcast sayMineExplode message then broadcast deaths and damageTaken messages and update GUI
    */
    fun {BroadcastMineExplode ID Position}
        fun {BroadcastLoop PlayerID ID Position PlayersDead}
            if PlayerID =< Input.nbPlayers then Message in
                {Send PlayersRecord.PlayerID sayMineExplode(ID Position ?Message)}
                case Message
                of sayDeath(Id) then
                    {Broadcast sayDeath(Id)}
                    {Send GuiPort removePlayer(Id)}
                    {BroadcastLoop PlayerID+1 ID Position PlayersDead+1}
                [] sayDamageTaken(Id Damage LifeLeft) then
                    {Broadcast sayDamageTaken(Id Damage LifeLeft)}
                    {Send GuiPort lifeUpdate(Id LifeLeft)}
                    {BroadcastLoop PlayerID+1 ID Position PlayersDead}
                else {BroadcastLoop PlayerID+1 ID Position PlayersDead}
                end
            else
                PlayersDead
            end
        end
    in
        {BroadcastLoop 1 ID Position 0}
    end

    /*
    * broadcast sayPassingDrone to all players and send the answers to the sender of the drone
    */
    proc {BroadcastPassingDrone Drone SenderID}
        proc {BroadcastLoop PlayerID Drone SenderID}
            if PlayerID =< Input.nbPlayers then ?ID ?Answer in
                {Send PlayersRecord.PlayerID sayPassingDrone(Drone ?ID ?Answer)}
                if ID==null then
                    {BroadcastLoop PlayerID+1 Drone SenderID}
                else
                    {Send PlayersRecord.SenderID sayAnswerDrone(Drone ID Answer)}
                    {BroadcastLoop PlayerID+1 Drone SenderID}
                end
            end
        end
    in
        {BroadcastLoop 1 Drone SenderID}
    end

    /*
    * broadcast sayPassingSonar to all players and send the answers to the sender of the drone
    */
    proc {BroadcastPassingSonar SenderID}
        proc {BroadcastLoop PlayerID SenderID}
            if PlayerID =< Input.nbPlayers then ?ID ?Answer in
                {Send PlayersRecord.PlayerID sayPassingSonar(?ID ?Answer)}
                if ID==null then
                    {BroadcastLoop PlayerID+1 SenderID}
                else
                    {Send PlayersRecord.SenderID sayAnswerSonar(ID Answer)}
                    {BroadcastLoop PlayerID+1 SenderID}
                end
            end
        end
    in
        {BroadcastLoop 1 SenderID}
    end

    /*
     * Server to update and get the number of alive players
     */
    fun {SimultaneousAlivePlayers}
        proc {Loop Msg AlivePlayersCounter}
            case Msg
            of dead(Nbr)|T then
                {Loop T AlivePlayersCounter-Nbr}
            [] get(?X)|T then
                X = AlivePlayersCounter
                {Loop T AlivePlayersCounter}
            end
        end
        P S
    in
        P = {NewPort S}
        thread {Loop S Input.nbPlayers} end
        P
    end

    /*
     * Turn by Turn
     */
    proc {TurnByTurn PlayerID SurfacesRecord AlivePlayersPort}
        NextID
        IsDead
        UpdatedSurfaces
    in
        if PlayerID == Input.nbPlayers then NextID=1 else NextID=PlayerID+1 end
        {Send PlayersRecord.PlayerID isDead(?IsDead)}

        if {Send AlivePlayersPort get($)} == 1 andthen IsDead == false then {System.show 'Youhou player'#PlayerID#', you won !'} %% 1 player left -> Game is over (stop condition)
        elseif {Send AlivePlayersPort get($)} == 0 then {System.show 'Ouch, it is a draw !'}
        else
        %% STEP 1 : check if can play
            if IsDead == true then % is dead ?
                {TurnByTurn NextID SurfacesRecord AlivePlayersPort}
            else
                if SurfacesRecord.PlayerID > 1 then %% or is at surface ?
                    UpdatedSurfaces = {Adjoin SurfacesRecord newValue(PlayerID:SurfacesRecord.PlayerID-1)}
                    {TurnByTurn NextID UpdatedSurfaces AlivePlayersPort}

                else MoveID Position Direction in

                    %% STEP 2 : dive if previous turn was last turn at surface of first round
                    if SurfacesRecord.PlayerID == 1 then
                        {Send PlayersRecord.PlayerID dive} end

                    %% Step 3 : ask submarine to choose a direction
                    {Send PlayersRecord.PlayerID move(?MoveID ?Position ?Direction)}
                    case Direction
                    %% STEP 4 : surface chosen, skip turn
                    of surface then
                        UpdatedSurfaces = {Adjoin SurfacesRecord newValue(PlayerID:Input.turnSurface)}
                        {Send GuiPort surface(MoveID)}
                        {TurnByTurn NextID UpdatedSurfaces AlivePlayersPort}

                    else ChargeID KindItem FireID KindFire MineID Mine MsgMine in
                        %%STEP 5 : broadcast direction and inform GUI
                        {Broadcast sayMove(MoveID Direction)}
                        {Send GuiPort movePlayer(MoveID Position)}

                        %STEP 6 : ask to charge an item and broadcast
                        {Send PlayersRecord.PlayerID chargeItem(?ChargeID ?KindItem)}
                        if KindItem \= null then {Broadcast sayCharge(ChargeID KindItem)} end

                        %STEP 7 : ask to fire an item and broadcast
                        {Send PlayersRecord.PlayerID fireItem(?FireID ?KindFire)}
                        case KindFire
                        of mine(Pos) then {Send GuiPort putMine(FireID Pos)} {Broadcast sayMinePlaced(FireID)}
                        [] missile(Pos) then DeadFromMissile in
                            {Send GuiPort explosion(FireID Pos)}
                            DeadFromMissile = {BroadcastMissileExplode FireID Pos}
                            {Send AlivePlayersPort dead(DeadFromMissile)}
                        [] drone(RorC V) then {Send GuiPort drone(FireID drone(RorC V))} {BroadcastPassingDrone KindFire FireID.id}
                        [] sonar then{BroadcastPassingSonar FireID.id}
                        else skip
                        end

                        %STEP 8 : ask to blow a mine and broadcast
                        {Send PlayersRecord.PlayerID fireMine(?MineID ?Mine)}
                        case Mine
                        of pt(x:X y:Y) then DeadFromMine in
                            {Send GuiPort explosion(MineID Mine)}
                            {Send GuiPort removeMine(MineID Mine)} DeadFromMine = {BroadcastMineExplode MineID Mine}
                            {Send AlivePlayersPort dead(DeadFromMine)}
                        else skip
                        end
                        if SurfacesRecord.PlayerID == 1 then
                            UpdatedSurfaces = {Adjoin SurfacesRecord newValue(PlayerID:SurfacesRecord.PlayerID-1)}
                        else
                            UpdatedSurfaces = SurfacesRecord
                        end
                        %STEP 9 : next player turn
                        {TurnByTurn NextID UpdatedSurfaces AlivePlayersPort}
                    end
                end
            end
        end
    end

    /*
     * Simultaneous : Loop executed by each submarine in simultaneous
     */
    proc {Simultaneous PlayerID AtSurface AlivePlayersPort}
        %% STEP 0 : Check if last alive player
        if {Send AlivePlayersPort get($)} == 1 andthen {Send PlayersRecord.PlayerID isDead($)} == false then {System.show 'Youhou player'#PlayerID#', you won !'}
        elseif {Send AlivePlayersPort get($)} == 0 then {System.show 'Ouch, it is a draw !'}
        else
            if {Send PlayersRecord.PlayerID isDead($)} == false then MoveID Position Direction in
            %% STEP 1 : wait turnSurface ms if at the surface then dive
                if AtSurface then {Send PlayersRecord.PlayerID dive} end

                %% STEP 2 : Simulate thinking
                {SimulateThinking}
                %% STEP 3 : Ask the player to choose its direction
                {Send PlayersRecord.PlayerID move(?MoveID ?Position ?Direction)}
                if MoveID \= null andthen Direction == surface then
                    {Send GuiPort surface(MoveID)}
                    {Delay Input.turnSurface}
                    {Simultaneous PlayerID true AlivePlayersPort}
                else ChargeID KindItem FireID KindFire MineID Mine MsgMine in
                    %% STEP 5 : broadcast direction and inform GUI
                    if MoveID \= null then
                        {Broadcast sayMove(MoveID Direction)}
                        {Send GuiPort movePlayer(MoveID Position)}
                    end

                    %% STEP 6 : Simulate thinking
                    {SimulateThinking}

                    %% STEP 7 : ask to charge an item and broadcast
                    {Send PlayersRecord.PlayerID chargeItem(?ChargeID ?KindItem)}
                    if ChargeID \= null andthen KindItem \= null then {Broadcast sayCharge(ChargeID KindItem)} end

                    %% STEP 8 : Simulate thinking
                    {SimulateThinking}

                    %% STEP 9 : ask to fire an item and broadcast
                    {Send PlayersRecord.PlayerID fireItem(?FireID ?KindFire)}
                    if FireID \= null then
                        case KindFire
                        of mine(Pos) then {Send GuiPort putMine(FireID Pos)} {Broadcast sayMinePlaced(FireID)}
                        [] missile(Pos) then DeadFromMissile in
                            {Send GuiPort explosion(FireID Pos)}
                            DeadFromMissile = {BroadcastMissileExplode FireID Pos}
                            {Send AlivePlayersPort dead(DeadFromMissile)}
                        [] drone(RorC V) then {Send GuiPort drone(FireID drone(RorC V))} {BroadcastPassingDrone KindFire FireID.id}
                        [] sonar then {BroadcastPassingSonar FireID.id}
                        else skip
                        end
                    end

                    %% STEP 10 : Simulate thinking
                    {SimulateThinking}
                    %STEP 11 : ask to blow a mine and broadcast
                    {Send PlayersRecord.PlayerID fireMine(?MineID ?Mine)}
                    if MineID \= null then
                        case Mine
                        of pt(x:X y:Y) then DeadFromMine in
                            {Send GuiPort explosion(MineID Mine)}
                            {Send GuiPort removeMine(MineID Mine)} DeadFromMine = {BroadcastMineExplode MineID Mine}
                            {Send AlivePlayersPort dead(DeadFromMine)}
                        else skip
                        end
                    end
                    %% STEP 12 : next turn
                    {Simultaneous PlayerID false AlivePlayersPort}
                end
            end
        end
    end

    %%% Start Simultaneous threads %%%
    proc {StartSimultaneousPlayers AlivePlayersPort}
        proc {StartPlayersLoop PlayerID}
            if PlayerID =< Input.nbPlayers then
                thread {Send PlayersRecord.PlayerID dive} {Simultaneous PlayerID false AlivePlayersPort} end
                {StartPlayersLoop PlayerID+1}
            end
        end
    in
        {StartPlayersLoop 1}
    end

    %%%% Initialize the User Interface %%%%
    GuiPort = {GUI.portWindow}
    {Send GuiPort buildWindow}

    %%%% Initialize the players %%%%
    PlayersRecord = {InitPlayers Input.players Input.colors 1 playersRecord()}
    {InitPosition 1}

    %%%% Initialize surface counters record %%%%
    InitSurfacesRecord = {InitSurfaces 1 surfacesRecord()}

    %%%% Game mode choosing %%%%
    if Input.isTurnByTurn then AlivePlayersPort in
        AlivePlayersPort = {SimultaneousAlivePlayers}
        {TurnByTurn 1 InitSurfacesRecord AlivePlayersPort}
    else AlivePlayersPort in
        %%% Initialize alive players counter %%%
        AlivePlayersPort = {SimultaneousAlivePlayers}
        {StartSimultaneousPlayers AlivePlayersPort}
    end
end
