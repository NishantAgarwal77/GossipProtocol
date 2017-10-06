defmodule PushSumWorkers do
    def start_link(numNodes) do
        currentNodeName="nodeCounter"
        GenServer.start_link(__MODULE__,[numNodes],name: String.to_atom(currentNodeName))
    end 

    def init([total_nodes]) do
        IO.puts "Node Counter started"        
        map= %{"total_nodes" =>total_nodes, "completedNodeCount" => 0, "nodeList" => []} 
        {:ok,map}
    end

    def handle_call({:incrementCounter, nodeNumber},_from,state) do 
        total = Map.get(state,"total_nodes")
        completed = Map.get(state,"completedNodeCount")
        completedNodeList = Map.get(state,"nodeList")
        completed = completed + 1
        completedNodeList = [nodeNumber | completedNodeList]

        if completed == total do
            [{_, time}] = :ets.lookup(:num_nodes_lookup, "start_time")
            total_time_taken = :os.system_time(:milli_seconds) - time
            IO.puts "Network has converged in #{total_time_taken} milliseconds"  
        end

        state = Map.put(state,"completedNodeCount",completed)
        state = Map.put(state,"nodeList",completedNodeList)       

        {:reply, completed, state}
    end
end