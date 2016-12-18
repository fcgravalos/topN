### topN

Usage:
  - Create a numbers file: `ruby file_generator.rb numbers.txt n_lines
    max`
  - From that file: `ruby topN.rb numbers.txt N`

### Cluster mode Proof of concept
#### Performance vs Scalability
If you have a machine with memory and CPU cores enough to process large files that's fine.

But resources are limited and at some point you are going to run out of hardware capacity
if you have too many files to process, so we need to scale.

For one small file, scalability is not the problem, we need just performance and the solution
provided above just works, but let's think about an architecture that allows us to scale when
we are dealing with really big files.

#### MapReduce paradigm
The common pattern to resolve big files processing is the MapReduce paradigm, Hadoop is the 
most famous open-source implementation of it and basically tries to split responsibilities: 
splitting, processing and aggregation amongst a cluster of nodes.

#### This example
Given that I'm not a Big Data/Hadoop expert and for the sake of simplicity I will implement a 
MapReduce architecture based of queues and cache with Aws SQS and Redis. The implementation is
not tied to a vendor, to use a different queue/cache provider you just need to implement the
right interface.

#### TopN Cluster architecture

![TopN Cluster Architecture](https://docs.google.com/uc?id=0B4SrwTszufE_X1ZldTNnd3BEd28)

- One master node that split the file in pieces and sends the path to the *chunks_queue*
- As many worker nodes as you define via command line or configuration file, listening on 
the *chunks_queue*.
- At the time I was coding this SQS FIFO queues were not available in Europe regions, so 
I decided to add a cache to store *key/value* pairs representing already processed messages.
So the workers keep track of already processed messages and don't process the same chunk 
multiple times.
- After processing the chunk, every worker node send the result to the *results_queue* and
the master finally aggregates all results and prints it.

#### Usage
`ruby bin/cluster.rb start [options] <file> <n>`

#### Caveats
- SQS payload limit is 256KB that forces us to split with a size lower than 256KB.
- With SQS FIFO implemantation we may get rid of Redis. But can be useful for other purposes.
- For simplicity everything is running on the same machine. This is just an example. To go further
on this I would like to use different nodes, the master node should run NFS Server, EFS, or a FUSE
implementation that allows network sharing and having a good storage backend.
