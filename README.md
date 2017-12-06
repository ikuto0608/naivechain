# naivechain
A blockchain implementation in 141 lines of code

This code is inspired by [lhartikk/naivechain](https://github.com/lhartikk/naivechain)

### Quick start
```
irb
```

```
require './naivechain.rb'
node = Node.new(6000)
```

Then once you create the node instance, it's gonna start mining, you can see increase the amount of blockchain
```
puts node.blockchain.count
```

If you want to run other node, then run like this
```
other_node = Node.new(6001, [6000])
```

The nodes are gonna connect in p2p.
