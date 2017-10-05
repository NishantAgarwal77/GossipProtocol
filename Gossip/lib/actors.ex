defmodule WorkerModule do
    
    def start_link(nodeId, numNodes, topology) do
        currentNodeName="node_"<>Integer.to_string(nodeId)
        GenServer.start_link(__MODULE__,[nodeId, numNodes, topology],name: String.to_atom(currentNodeName))
    end   

    def init([nodeId, total_nodes, topology]) do
        IO.puts "Genserver started"        
        map= %{"id" => nodeId,"total_nodes" =>total_nodes,"neighbours" =>[],"msg_count" =>0}      
        if topology =="full" do           
            state=buildFullTopology(map)                      
        end
        {:ok,state}
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
        currentNodeName="node"<> Integer.to_string(current_node)   
        if(Map.get(state,"process_id") == nil) do            
            process_pid=spawn fn -> sendMessage(currentNodeName, neighbours, msg) end
            state=Map.put(state,"process_id",process_pid)
        end
        current_msg_count=Map.get(state,"msg_count")
        current_msg_count=current_msg_count+1
        state = Map.put(state,"msg_count",current_msg_count)
        if(current_msg_count == 10) do
            IO.puts "exited node" <>Integer.to_string(current_node) 
            [{_, count}] = :ets.lookup(:num_nodes_lookup, "num_nodes") 
            :ets.insert(:num_nodes_lookup, {"num_nodes", count - 1})  
            Process.exit(Map.get(state,"process_id"),:kill)           
        end       
        {:reply,state,state}
    end

    def sendMessage(current_Node, neighbours, msg) do
        [{_, count}] = :ets.lookup(:num_nodes_lookup, "num_nodes") 
        if count <=1 do
            IO.puts "exited " <> current_Node          
            [{_, time}] = :ets.lookup(:num_nodes_lookup, "start_time")
            total_time_taken = :erlang.system_time - time
            IO.puts "Network has converged in " <> Integer.to_string(total_time_taken)
            Process.exit(self(),:kill)            
        end
        random_num=Enum.random(neighbours)
        random_node="node_"<>Integer.to_string(random_num)
        random_pid=Process.whereis(String.to_atom(random_node))
        if(random_pid !=nil && Process.alive?(random_pid)==true) do
            GenServer.call(String.to_atom(random_node),{:passMessage,msg})
        end      
        sendMessage(current_Node, neighbours, msg)
    end
end