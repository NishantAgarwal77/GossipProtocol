# GossipProtocol
Implementing Gossip and Push Sum Algorithm

## Team Members
Nishant Agarwal (UFID:61991874) and Moulik Agarwal (UFID:3982674)

## What is Working
We have successfully implemented the `Gossip` and `Push-Sum` Algorithm over Topologies
```
1) Full Network
2) Line Network
3) 2D Grid Network
4) Imperfect 2D Network
```

By successfull implemetation we imply that the network converges (according to the definition of the algorithm) for the provided number of nodes in the network.

## Largest Network Details
Below is the tabular representation of the largest network of nodes used for both the algorithm with each type of typology :

|                       | Full Topology | Line Topology | 2D Topology  | Imp 2D Topology |
| ------------------    |:-------------:| -------------:| ------------:|----------------:|
| Gossip Algorithm      | `20000`       |   `40300`     |  `30000`     |    `40000`      |   
| Push - Sum Algorithm  |  `5000`       |   `30000`     |   `20000`    |    `20000`      |


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `gossip` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:gossip, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/gossip](https://hexdocs.pm/gossip).

