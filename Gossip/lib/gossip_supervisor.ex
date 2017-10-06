defmodule GossipChildModule do
    use Supervisor

    def start_link(numNodes, topology, algorithm) do
        Supervisor.start_link(__MODULE__, [numNodes, topology, algorithm])
    end

    def init([numNodes, topology, algorithm]) do
        IO.puts("Gossip Supervisor Started")        
        children = create_gossip_children(numNodes, topology, algorithm)
        children = [worker(PushSumWorkers, [numNodes]) | children]
        IO.puts "All actors created"          
        supervise(children, strategy: :one_for_one)          
    end

    def create_gossip_children(totalNumberNodes,topology, algorithm) do        
        childrenWorkerList = Enum.reduce(1..totalNumberNodes, [], fn(x, acc) -> [worker(WorkerModule, [x, totalNumberNodes, topology, algorithm], [id: x, restart: :temporary]) | acc] end)
        childrenWorkerList
    end   
end