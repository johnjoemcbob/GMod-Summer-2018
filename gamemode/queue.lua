--
-- Prickly Summer 2018
-- 07/07/18
--
-- A basic circular queue container.
--

function PRK_Queue_Create(capacity)
    if(capacity < 1) then
        capacity = 1
    end
    local queue = {}
    queue.capacity = 0
    queue.current_access_index = 0
    queue.list = {}
    
    PRK_Queue_Extend(queue, capacity)
        
    return queue
end

function PRK_Queue_Push(queue, element)
    queue[queue.current_access_index] = element
    
    PRK_Queue_Recede(queue)
    print("Queue Push: " .. tostring(queue.current_access_index) .. " + " .. tostring(element))
end

function PRK_Queue_Access(queue)
    print("Queue accessed: " .. tostring(queue[queue.current_access_index]))

    return queue[queue.current_access_index]
end

function PRK_Queue_Advance(queue)
    queue.current_access_index = queue.current_access_index - 1
    if(queue.current_access_index < 0) then
        queue.current_access_index = queue.capacity - 1
    end
end

function PRK_Queue_Recede(queue)
    queue.current_access_index = queue.current_access_index + 1
    if(queue.current_access_index >= queue.capacity) then
        queue.current_access_index = 0
    end
end

function PRK_Queue_ShuffleAccessIndex(queue)
    print("Shuffling Access...")
    queue.current_access_index = math.random(0, queue.capacity - 1)
    print(tostring(queue.current_access_index))
end

function PRK_Queue_Pop(queue)
    local queue_top = PRK_Queue_Access(queue)
    queue[queue.current_access_index] = {}
    PRK_Queue_Advance(queue)
    
    return queue_top
end

function PRK_Queue_Extend(queue, num_elements_add)
    for i = queue.capacity,(queue.capacity + num_elements_add) do
        queue.list[i] = {}
    end
    
    queue.capacity = queue.capacity + num_elements_add
end

function PRK_Queue_Shrink(queue, num_elements_remove)
    queue.capacity = queue.capacity - num_elements_remove
    if(queue.capacity < 0) then
        queue.capacity = 0
    end
end

