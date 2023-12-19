# PESO SERVER

## NOTE

This is a `WIP` containing planned functionality.

##

`AR/Via` (short `Via`) refers to the IPC model used by `peso`.

To describe the model in short: complex tasks such as graphics are relegated to a central monolith that services smaller programs, ie a star network of processes.

Nodes in the network are thus either `client` or `server`, both derived from the `netstruc` base format. It consists of a unix `socket` and a shared memory block (`shmem`), both being stored as pointers to their respective `bin` wrappers.

The socket is utilized almost solely for synchronization and the odd directed message; shared memory is largely preferred for moving data. A `server` owns *all* of the memory block, and allocates partitions of it to each `client`, making note of their addresses into an array of peers; requesting addresses from this table can be used for communication across `client` nodes.

Each partition is split into two `IO` segments: `out` is meant solely for a `server` to read and interpret, while `in` is for use by the `client` itself; each `client` can make use of it's `out` segment to make server requests, whereas queing a write to the `in` segment is effectively messaging.

`server` nodes are tasked with linking and unlinking the backing files at the beg and end of their execution; `client` nodes can only ever 'open' them.

The `loop` routine for both types of nodes consists of four branches: `read`, `ipret`, `logic` and `write`. For illustration, consider the following tree:

```$

(read)
\-->have in?
.  \-->call node->read in
.  \-->^^push to pending
.
.
(ipret)
\-->have pending?
.  \-->call node->ipret pending
.  \-->^^have msg?
.  .  \-->push message to out
.
.
(logic)
\-->node updated?
.  \-->call node->logic
.  \-->^^have msg?
.  .  \-->push message to out
.
.
(write)
have out?
\-->call node->write

```

The mechanisms by which this program structure is guaranteed is inherited through `netstruc`; base `server` and `client` nodes build on top of it, and instances of either type of node provide the instance-specific methods, __if__ the `defproc` is insufficient.

Writes to the `in` segment are only locked if the destination buffer is too full to accept another message and the writer is a `client`. Otherwise, the provided write size is atomically added to an internal counter, with the prior size check being atomic as well.

The `AR/Via` model dictates that `client to client` communication through their respective `in` segments is given priority over `server to client` through the same medium, specifically due to the `socket` within `netstruc` being there for this exact type of communication in case of emergency, the use of which should by definition be infrequent.

Thus, if a `client in` is unable to receive a message from the `server`, the message will simply be queued for the next frame.

On growing input queues due to high traffic, the `server` will choose between a `realloc` or `shutdown`; `netstruc` provides a `defproc` for it which an instance of `server` may freely overwrite.

During `client to server` communication, on the other hand, the `out` segment will always be locked by either end. If the `server` fails to acquire the lock during this time, the buffer will be skipped for a frame, at which point the `client` will opt for discarding the oldest message if output queues grow past a configurable threshold. In the case of loss of this data being unacceptable, an instance of `client` may overwrite `backout` to temporarily extend it's output queue.

But if the `backout` queue grows past the acceptable limit, set by the `server`, a `client` can and most likely *will* get the `kick` or `hammer` in accordance to the `ban` policy set by the `server`; and whereas `kick` can be set to `revoke` after a given period of time, in the latter case `revoke` may only be called manually. For more information about revoking of eternal prohibition, head to the local temple on a moonless night and consult the Elder Matriarch.

