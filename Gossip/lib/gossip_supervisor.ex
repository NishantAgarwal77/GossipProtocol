defmodule GossipChildModule do
    use Supervisor

    def start_link(numNodes, topology) do
        Supervisor.start_link(__MODULE__, [numNodes, topology])
    end

    def init([numNodes, topology]) do
        IO.puts("Gossip Supervisor Started")       
        children = create_children(numNodes, topology) 
        IO.puts "All actors created"          
        supervise(children, strategy: :one_for_one)          
    end

    def create_children(totalNumberNodes,topology) do        
        childrenWorkerList = Enum.reduce(1..totalNumberNodes, [], fn(x, acc) -> [worker(WorkerModule, [x, totalNumberNodes, topology], [id: x, restart: :temporary]) | acc] end)
        childrenWorkerList
    end
end