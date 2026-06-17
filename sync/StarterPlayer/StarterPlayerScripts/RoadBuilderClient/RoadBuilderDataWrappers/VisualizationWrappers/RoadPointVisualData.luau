export type RoadPointVisualData = {
    roadPointInstance: BasePart;
    destructor: () -> ();
}

return function(
    roadPointInstance: BasePart,
    destructor: () -> ()
): RoadPointVisualData
    return {
        roadPointInstance = roadPointInstance;
        
        destructor = destructor;
    }
end
