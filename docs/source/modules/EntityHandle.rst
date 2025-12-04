EntityHandle
============
An entity handle is a wrapper around a ``GameEntity`` (typically an ``IsoObject``).
An entity handle knows when the underlying entity has unloaded and drops the reference.
This is important because entities are subject to object pooling,
which means that holding a raw reference to an entity could result in that object being reused for a 'new' entity.
If you're storing a reference to an entity over multiple ticks,
there is usually a chance that the entity will unload and be reused:
therefore a handle is a superior choice to a raw reference in these instances.

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

To safely access the entity afterwards, check :lua:meth:`isEmpty()` and then use :lua:meth:`get()` to retrive the underlying entity.
::

    local handle = EntityHandle.get(entity)

    function doSomethingWithEntityEveryTick()
        if not handle:isEmpty() then
            local entity = handle:get()
            doSomethingWithEntity(entity)
        else
            -- if the handle is empty, the entity has unloaded
            print("Entity unloaded")
            -- an empty handle will never be full again,
            --  so you should cancel whatever you're doing with it and drop the reference
            handle = nil
            Events.OnTick.Remove(doSomethingWithEntityEveryTick)
        end
    end

    Events.OnTick.Add(doSomethingWithEntityEveryTick)

Note how we pass the raw entity into our ``doSomethingWithEntity()`` function and not the handle:
There is no need to check :lua:meth:`~starlit.EntityHandle.isEmpty()`
or retrieve the entity with :lua:meth:`~starlit.EntityHandle.get()` more than once
because we know an entity won't suddenly unload in the middle of our code.
It is much more natural and compatible to pass around the entity itself.
Only use the handle when you don't know if the entity is still loaded or not.
