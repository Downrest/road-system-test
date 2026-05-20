[x] instead of caching road data on the server purely, with the client sending requests via remotefunctions. it would be better to instead have the server send out a copy of the cache over to the client (everytime a new cache object is made). 

this is convenient because the client accesses the RoadBuilderCache directly (rather than an ambigious event such as RequestRoadData). 

for syncing concerns, ill add a yield function that lets you yield until a specific object has appeared in cache!