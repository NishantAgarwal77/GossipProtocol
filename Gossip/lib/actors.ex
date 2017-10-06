defmodule WorkerModule do
    
    def start_link(nodeId, numNodes, topology, algorithm) do
        currentNodeName="node_"<>Integer.to_string(nodeId)
        GenServer.start_link(__MODULE__,[nodeId, numNodes, topology, algorithm],name: String.to_atom(currentNodeName))
    end   

    def init([nodeId, total_nodes, topology, algorithm]) do        
        map = case algorithm do
            "gossip" -> 
             %{"id" => nodeId,"total_nodes" =>total_nodes,"neighbours" =>[],"msg_count" =>0} 
            "push-sum" ->     
             %{"id" => nodeId,"total_nodes" =>total_nodes,"neighbours" =>[],"SValue" => nodeId, "WValue" => 1, "consecutiveCount" => 0}       
        end                
       if topology =="full" do
            #IO.puts "Full topology detected"
            state=buildFullTopology(map)
            #IO.puts "Full topology generated"
        end
        if topology == "line" do            
            state=buildLineTopology(map)            
        end
        if topology == "2D" do            
            n= round :math.ceil(:math.sqrt(total_nodes))
            total_nodes=n*n 

            Map.put(map,"total_nodes",total_nodes)
            state=build2DTopology(map)           
        end
        if topology == "imp2D" do           
            n= round :math.ceil(:math.sqrt(total_nodes))
            total_nodes=n*n 
            Map.put(map,"total_nodes",total_nodes)
            state=buildImp2DTopology(map)           
        end
        {:ok,state}
    end

     def getRandomNeighbour(list,total_nodes) do
        rand=Enum.random(1..total_nodes)
        if(Enum.member?(list,rand)) do
            rand=getRandomNeighbour(list,total_nodes)
        end
        rand
    end
    def getImp2DTopoNeighbours(n,total_nodes,current_node) do
        twoD_neighbours=get2DTopoNeighbours(n,current_node)
        augmented_list=[current_node | twoD_neighbours ]
        random_num=getRandomNeighbour(augmented_list,total_nodes)
        twoD_neighbours= [random_num | twoD_neighbours]
        twoD_neighbours
    end

    def buildImp2DTopology(state) do
        total_nodes=Map.get(state,"total_nodes")
        n=round :math.ceil(:math.sqrt(total_nodes))
        current_node=Map.get(state,"id");
        neighbours=getImp2DTopoNeighbours(n,total_nodes,current_node)
        state=Map.put(state,"neighbours",neighbours)
        state
    end

    def get2DTopoNeighbours(n,current_node) do
        neighbours=[]
        col=round :math.fmod(current_node,n)
        below=current_node-n
        if(below >0) do
            neighbours=[below | neighbours]
        end
        up=current_node+n
        if(up<=n*n) do
            neighbours=[up | neighbours]
        end

        if( col==0) do
            neighbours=[current_node - 1 | neighbours]
        end
        if(col == 1) do
            neighbours = [current_node + 1 | neighbours]
        end
        if(col > 1) do
            neighbours = [current_node - 1 | neighbours]
            neighbours = [current_node + 1 | neighbours]
        end
        neighbours
    end
    def build2DTopology(state) do
        total_nodes=Map.get(state,"total_nodes")
        n=round :math.ceil(:math.sqrt(total_nodes))
        current_node=Map.get(state,"id");
        neighbours=get2DTopoNeighbours(n,current_node)
        state=Map.put(state,"neighbours",neighbours)
        state
    end

    def getLineTopoNeighbours(current_node,total_nodes) do
        result=[];
        if(current_node == 1) do
            result=[current_node + 1 | result]
        end
        if(current_node == total_nodes) do
            result=[current_node - 1 | result]
        end
        if(current_node > 1 && current_node < total_nodes) do
            result= [current_node + 1 | result]
            result= [current_node - 1 | result]
        end
        result
    end

    def buildLineTopology(state) do
        total_nodes=Map.get(state,"total_nodes")
        current_node=Map.get(state,"id");
        neighbours=getLineTopoNeighbours(current_node,total_nodes)
        state=Map.put(state,"neighbours",neighbours)
        state
    end

    def buildFullTopology(state) do
        total_nodes=Map.get(state,"total_nodes")
        current_node=Map.get(state,"id");
        neighbours=getFullTopoNeighbours(current_node,total_nodes)
        state=Map.put(state,"neighbours",neighbours)
        state
    end

    def getFullTopoNeighbours(current_node,total_nodes) do
        nodes = 1..total_nodes
        node_list = Enum.to_list(nodes)
        node_list = List.delete(node_list, current_node)
        node_list
    end

    def handle_call({:passMessage,msg},_from,state) do       
        neighbours=Map.get(state,"neighbours")
        current_node =  Map.get(state,"id") 
        #current_msg_count = Map.get(state,"msg_count")
        currentNodeName="node"<> Integer.to_string(current_node)
        #IO.inspect _from
        #IO.inspect "Node_" <> Integer.to_string(current_node) <> " received " <> msg <> " with count " <> Integer.to_string(current_msg_count)
        if(Map.get(state,"process_id") == nil) do            
            count = GenServer.call(String.to_atom("nodeCounter"), {:incrementCounter, current_node})
            process_pid = spawn fn -> sendMessage(currentNodeName, neighbours, msg) end
            state=Map.put(state,"process_id",process_pid)
            if count == Map.get(state,"total_nodes") do               
                if Process.alive?(Map.get(state, "process_id"))==true do
                    Process.exit(Map.get(state, "process_id"),:kill)     
                end 
            end            
        end
        current_msg_count=Map.get(state,"msg_count")
        current_msg_count=current_msg_count+1
        state = Map.put(state,"msg_count",current_msg_count)
        if(current_msg_count == 10) do
            #IO.puts "exited node" <>Integer.to_string(current_node)                        
            Process.exit(Map.get(state,"process_id"),:kill)           
        end       
        {:reply,state,state}
    end

    def sendMessage(current_Node, neighbours, msg) do
        [{_, count}] = :ets.lookup(:num_nodes_lookup, "num_nodes")
        if count > 0 do 
            random_num=Enum.random(neighbours)
            random_node="node_"<>Integer.to_string(random_num)
            random_pid=Process.whereis(String.to_atom(random_node))
            if(random_pid !=nil && Process.alive?(random_pid)==true) do
                GenServer.call(String.to_atom(random_node),{:passMessage,msg})
            end      
            sendMessage(current_Node, neighbours, msg)           
        end                 
    end

    def handle_cast({:pushMessage, sValue, wValue}, state) do             
        prevSValue = Map.get(state, "SValue")     
        prevWValue = Map.get(state, "WValue")
        #IO.puts "s = #{prevSValue}, w = #{prevWValue}"    
        prevRatio  = prevSValue / prevWValue
        newSValue = (prevSValue + sValue) / 2
        newWValue = (prevWValue + wValue) / 2
        newRatio = newSValue / newWValue
        timeOfUnChangedRatio = Map.get(state, "consecutiveCount")
        neighbours = Map.get(state,"neighbours")
        current_node =  Map.get(state,"id")        
        currentNodeName = "node_"<> Integer.to_string(current_node)
        ratioDiff = abs(newRatio - prevRatio)
        if ratioDiff <= 10.0e-10 do
            timeOfUnChangedRatio = timeOfUnChangedRatio + 1
        else 
            timeOfUnChangedRatio = 0
        end
        if timeOfUnChangedRatio < 3 do
            #IO.puts ratioDiff
            sendPushMessage(neighbours, newSValue, newWValue)
        else 
            [{_, time}] = :ets.lookup(:num_nodes_lookup, "start_time")
            timeTaken = :os.system_time(:milli_seconds) - time
            IO.puts "Node #{current_node} has reached convergence, hence exiting"
            IO.puts "Network has converged in #{timeTaken} milliseconds"            
            GenServer.stop(String.to_atom(currentNodeName), :normal)
        end
        state = Map.put(state,"SValue",newSValue)
        state = Map.put(state,"WValue",newWValue)
        state = Map.put(state,"consecutiveCount",timeOfUnChangedRatio)
        {:noreply,state}
    end

    def sendPushMessage(neighbours, newSValue, newWValue) do               
        random_num=Enum.random(neighbours)
        random_node="node_"<>Integer.to_string(random_num)
        random_pid=Process.whereis(String.to_atom(random_node))
        if(random_pid !=nil && Process.alive?(random_pid)==true) do
            GenServer.cast(String.to_atom(random_node),{:pushMessage,newSValue, newWValue}) 
        else 
            sendPushMessage(neighbours, newSValue, newWValue)
        end                     
    end 
end