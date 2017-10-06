defmodule WorkerModule do
    
    def start_link(nodeId, numNodes, topology) do
        currentNodeName="node_"<>Integer.to_string(nodeId)
        GenServer.start_link(__MODULE__,[nodeId, numNodes, topology],name: String.to_atom(currentNodeName))
    end   

    def init([nodeId, total_nodes, topology]) do
        #IO.puts "Genserver started"        
        map= %{"id" => nodeId,"total_nodes" =>total_nodes,"neighbours" =>[],"msg_count" =>0}      
       if topology =="full" do
            #IO.puts "Full topology detected"
            state=buildFullTopology(map)
            #IO.puts "Full topology generated"
        end
        if topology == "line" do
            IO.puts "line topology detected"
            state=buildLineTopology(map)
            IO.puts "Line Topology Created"
        end
        if topology == "2D" do
            IO.puts "2D topology detected"
            n= round :math.ceil(:math.sqrt(total_nodes))
            total_nodes=n*n 
            Map.put(map,"total_nodes",total_nodes)
            state=build2DTopology(map)
            IO.puts "2D Topology Created"
        end
        if topology == "imp2D" do
            IO.puts "Imp2D topology detected"
            n= round :math.ceil(:math.sqrt(total_nodes))
            total_nodes=n*n 
            Map.put(map,"total_nodes",total_nodes)
            state=buildImp2DTopology(map)
            IO.puts "Imp2D Topology Created"
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
        neighbours=getFullTopoNeighbours(current_node,total_nodes,[])
        state=Map.put(state,"neighbours",neighbours)
        state
    end

    def getFullTopoNeighbours(_,total_nodes,node_list) when total_nodes<1 do
        node_list
    end

    def getFullTopoNeighbours(current_node,total_nodes,node_list) do
        if(total_nodes != current_node) do
            node_list=[total_nodes|node_list]
        end
        getFullTopoNeighbours(current_node,total_nodes-1,node_list)
    end

    def handle_call({:passMessage,msg},_from,state) do
        #IO.puts state
        neighbours=Map.get(state,"neighbours")
        current_node =  Map.get(state,"id") 
        #current_msg_count = Map.get(state,"msg_count")
        currentNodeName="node"<> Integer.to_string(current_node)
        #IO.inspect _from
        #IO.inspect "Node_" <> Integer.to_string(current_node) <> " received " <> msg <> " with count " <> Integer.to_string(current_msg_count)
        if(Map.get(state,"process_id") == nil) do  
            #IO.puts current_node
             [{_, count}] = :ets.lookup(:num_nodes_lookup, "num_nodes") 
            :ets.insert(:num_nodes_lookup, {"num_nodes", count - 1})
            count = count - 1
            process_pid=spawn fn -> sendMessage(currentNodeName, neighbours, msg) end
            state=Map.put(state,"process_id",process_pid)
            if count == 0 do
                #IO.puts "exited " <> currentNodeName
                #[{_, time}] = :ets.lookup(:num_nodes_lookup, "start_time")
                #total_time_taken = :erlang.system_time - time
                #IO.puts "Network has converged in " <> Integer.to_string(total_time_taken)
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
end