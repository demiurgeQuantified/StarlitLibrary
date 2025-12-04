EntityHandle
============
An entity handle is a wrapper around a ``GameEntity`` (typically an ``IsoObject``).
An entity handle knows when the underlying entity has unloaded and drops the reference.
This is important because entities are subject to object pooling,
which means that that object could have been reused for a 'new' entity when you next try to access it.
If you're storing a reference to an entity over multiple ticks,
there is usually a chance that the entity will unload and be reused:
a handle is a safer choice than a raw reference in these instances.

.. lua:automodule:: Starlit.EntityHandle
    :members:
    :recursive:

.. lua:autoclass:: starlit.EntityHandle
    :members:
    :recursive:

Usage
-----
After obtaining a reference to an entity, use the module to get its entity handle.
::

    local handle = EntityHandle.get(entity)

To safely access the entity afterwards, use :lua:meth:`~starlit.EntityHandle.get()` to retrive the underlying entity.
::

    local handle = EntityHandle.get(entity)

    function doSomethingWithEntityEveryTick()
        local entity = handle:get()
        if entity then
            doSomethingWithEntity(entity)
        else
            -- if get() returns nil, the entity has unloaded
            print("Entity unloaded")
            -- a handle that has returned nil is considered 'dead' and will never have an object again,
            --  so you should cancel whatever you're doing with it and drop the reference
            handle = nil
            Events.OnTick.Remove(doSomethingWithEntityEveryTick)
        end
    end

    Events.OnTick.Add(doSomethingWithEntityEveryTick)

Note how we pass the raw entity into our ``doSomethingWithEntity()`` function and not the handle:
There is no need to call :lua:meth:`~starlit.EntityHandle.get()` more than once
because we know an entity won't suddenly unload in the middle of our function.
It is much more natural and compatible to pass around the entity itself.
Only use handles when you don't know if the entity will still be loaded when you next try to access it.
