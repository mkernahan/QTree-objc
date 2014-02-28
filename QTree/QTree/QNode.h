//
// This file is subject to the terms and conditions defined in
// file 'LICENSE.md', which is part of this source code package.
//

#import "QCluster.h"
#import "QTreeFilterController.h"
#import <MapKit/MapKit.h>

@interface QNode : NSObject

+(instancetype)nodeWithRegion:(MKCoordinateRegion)region filterController:(id<QTreeFilterController>)filterController;

-(instancetype)initWithRegion:(MKCoordinateRegion)region filterController:(id<QTreeFilterController>)filterController;

@property(nonatomic, readonly) MKCoordinateRegion region;
@property(nonatomic, readonly) NSUInteger count;
// Shortcuts
@property(nonatomic, readonly) CLLocationDegrees centerLatitude;
@property(nonatomic, readonly) CLLocationDegrees centerLongitude;

@property(nonatomic, readonly) id<QTreeFilterController> filterController;

-(BOOL)insertObject:(id<QTreeInsertable>)insertableObject;

-(NSArray*)getObjectsInRegion:(MKCoordinateRegion)region minNonClusteredSpan:(CLLocationDegrees)span;
// Returned array is sorted from the least to the most distant
-(NSArray*)neighboursForLocation:(CLLocationCoordinate2D)location limitCount:(NSUInteger)limit;

@end
