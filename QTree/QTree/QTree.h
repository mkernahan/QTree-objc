//
// This file is subject to the terms and conditions defined in
// file 'LICENSE.md', which is part of this source code package.
//

#import "QTreeInsertable.h"
#import "QTreeFilterController.h"
#import <MapKit/MapKit.h>

@interface QTree : NSObject <QTreeFilterController>

@property(nonatomic, readonly) NSUInteger count;

-(id)initWithFilterController:(id<QTreeFilterController>)filterController;

-(void)insertObject:(id<QTreeInsertable>)insertableObject;
- (void) clearCachedClusters;

-(NSArray*)getObjectsInRegion:(MKCoordinateRegion)region minNonClusteredSpan:(CLLocationDegrees)span;
// Returned array is sorted from the least to the most distant
-(NSArray*)neighboursForLocation:(CLLocationCoordinate2D)location limitCount:(NSUInteger)limit;

@end