defmodule GossipChildModule do
    use Supervisor

    def start_link(numNodes, topology, algorithm, mainProcessID) do
        Supervisor.start_link(__MODULE__, [numNodes, topology, algorithm, mainProcessID], name: __MODULE__)
    end

    def init([numNodes, topology, algorithm, mainProcessID]) do
        IO.puts("Gossip Supervisor Started")        
        children = create_gossip_children(numNodes, topology, algorithm, mainProcessID)
        children = [worker(PushSumWorkers, [numNodes, mainProcessID]) | children]
        IO.puts "All actors created"          
        supervise(children, strategy: :one_for_one)          
    end

    def create_gossip_children(totalNumberNodes,topology, algorithm, mainProcessID) do        
        childrenWorkerList = Enum.reduce(1..totalNumberNodes, [], fn(x, acc) -> [worker(WorkerModule, [x, totalNumberNodes, topology, algorithm, mainProcessID], [id: x, restart: :temporary]) | acc] end)
        childrenWorkerList
    end   
end