[x] instead of caching road data on the server purely, with the client sending requests via remotefunctions. it would be better to instead have the server send out a copy of the cache over to the client (everytime a new cache object is made). 

this is convenient because the client accesses the RoadBuilderCache directly (rather than an ambigious event such as RequestRoadData). 

for syncing concerns, ill add a yield function that lets you yield until a specific object has appeared in cache!

---

[x] MORE ABOUT CACHING, i should add a feature to batch remote event calls, the syntax would be something like

```luau
local batch = Cache.Batch()

batch.AddRoad(...)
batch.AddRoadPoint(...)

-- then eventually..
batch.Send() 
```

in other words, rather than each Add..() call firing a remote event to update client cache, we can merely batch the data from the Add..() calls and only then fire them all through one big remote event

---

[x] ANOTHER POINT! we need a way to get the direction of the newly created road from the client. i propose a public method from roadbuildercreation that lets us get the direction BY CALCULATING IT MANUALLY VIA THE CURVE since we just need that and do math. something like say `RoadBuilderCreation.GetRoadCurveDirection()`

---

[x] consider moving RoadBuilderAssetGetter out of RoadBuilderUtils? shrug


