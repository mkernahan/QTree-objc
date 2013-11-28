//
// This file is subject to the terms and conditions defined in
// file 'LICENSE.md', which is part of this source code package.
//

#import "QTree.h"
#import "QNode.h"

@interface QTree()

@property(nonatomic, strong) QNode* rootNode;

@end

@implementation QTree

-(id)init { return [self initWithFilterController:self]; }
-(id)initWithFilterController:(id<QTreeFilterController>)filterController
{
	if(!(self = [super init])) {
        return nil;
    }
	_rootNode = [[QNode alloc] initWithRegion:MKCoordinateRegionForMapRect(MKMapRectWorld) filterController:filterController];
	return self;
}

-(void)insertObject:(id<QTreeInsertable>)insertableObject
{
    [self.rootNode insertObject:insertableObject];
}

-(NSUInteger)count
{
    return self.rootNode.count;
}

- (void) clearCachedClusters {
    [_rootNode clearCachedClusters];
}

-(NSArray*)getObjectsInRegion:(MKCoordinateRegion)region minNonClusteredSpan:(CLLocationDegrees)span
{
	return [self.rootNode getObjectsInRegion:region minNonClusteredSpan:span];
}

-(NSArray*)neighboursForLocation:(CLLocationCoordinate2D)location limitCount:(NSUInteger)limit
{
	return [self.rootNode neighboursForLocation:location limitCount:limit];
}

#pragma mark - QTreeFilterController implementation

- (NSArray *) applyFilterToArrayOfInsertableObjects:(NSArray *)sourceArray {
    return sourceArray;
}

- (QCluster *) newQClusterObjectWithChildren:(NSArray *)children {
    return [[QCluster alloc] initWithChildren:children];
}

@end
