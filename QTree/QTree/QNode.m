//
// This file is subject to the terms and conditions defined in
// file 'LICENSE.md', which is part of this source code package.
//

#import "QNode.h"
#import "QTree.h"
#import "QTreeGeometryUtils.h"
#import <CoreLocation/CoreLocation.h>

static const CLLocationDistance MinDistinguishableMetersDistance = 0.5;

@interface QNode()

@property(nonatomic, assign) MKCoordinateRegion region;

@property(nonatomic, strong) id<QTreeInsertable> leadObject;
@property(nonatomic, strong) NSMutableSet* satellites;

@property(nonatomic, assign) NSUInteger count;

@property(nonatomic, strong) QCluster* cachedCluster;

@property(nonatomic, strong) QNode* upLeft;
@property(nonatomic, strong) QNode* upRight;
@property(nonatomic, strong) QNode* downLeft;
@property(nonatomic, strong) QNode* downRight;

@property(nonatomic, weak) id<QTreeFilterController> filterController;
@end

@implementation QNode

+(instancetype)nodeWithRegion:(MKCoordinateRegion)region filterController:(id<QTreeFilterController>)filterController
{
    return [[QNode alloc] initWithRegion:region filterController:filterController];
}


-(id)initWithRegion:(MKCoordinateRegion)region filterController:(id<QTreeFilterController>)filterController
{
    self = [super init];
    if( !self ) {
        return nil;
    }
    _region = region;
    _filterController = filterController;
    return self;
}

-(CLLocationDegrees)centerLatitude
{
    return self.region.center.latitude;
}

-(CLLocationDegrees)centerLongitude
{
    return self.region.center.longitude;
}

-(BOOL)isLeaf
{
    return !self.upLeft && !self.downLeft && !self.upRight && !self.downRight;
}

-(BOOL)insertObject:(id<QTreeInsertable>)insertableObject
{
    if( self.leadObject ) {
        if( CLMetersBetweenCoordinates(self.leadObject.coordinate, insertableObject.coordinate) >= MinDistinguishableMetersDistance ) {
            // Move self objects deeper
            NSAssert([self isLeaf], @"Node containing objects should be a leaf");
            [self insertLeadObject:self.leadObject withSatellites:self.satellites];
            self.leadObject = nil;
            self.satellites = nil;
        } else {
            if( ![self.leadObject isEqual:insertableObject] ) {
                self.count += 1;
                self.cachedCluster = nil;
                if( !self.satellites ) {
                    self.satellites = [NSMutableSet set];
                }
                [self.satellites addObject:insertableObject];
                return YES;
            } else {
                // Can't distinguish two objects
                return NO;
            }
        }
    }
    if( [self insertLeadObject:insertableObject withSatellites:nil] ) {
        self.count += 1;
        return YES;
    } else {
        return NO;
    }
}

-(BOOL)insertLeadObject:(id<QTreeInsertable>)leadObject withSatellites:(NSSet*)satellites
{
    self.cachedCluster = nil;
    
    QNode* __strong *pNode = nil;
    
    const BOOL down = leadObject.coordinate.latitude < self.centerLatitude;
    const BOOL left = leadObject.coordinate.longitude < self.centerLongitude;
    
    if( down ) {
        if( left ) {
            pNode = &_downLeft;
        } else {
            pNode = &_downRight;
        }
    } else {
        if( left ) {
            pNode = &_upLeft;
        } else {
            pNode = &_upRight;
        }
    }
    
    if( !*pNode ) {
        const CLLocationDegrees latDeltaBy2 = self.region.span.latitudeDelta / 2;
        const CLLocationDegrees newLat = self.centerLatitude + latDeltaBy2 * (down ? -1 : +1) / 2;
        
        const CLLocationDegrees lngDeltaBy2 = self.region.span.longitudeDelta / 2;
        const CLLocationDegrees newLng = self.centerLongitude + lngDeltaBy2 * (left ? -1 : +1) / 2;
        
        const CLLocationCoordinate2D newCenter = CLLocationCoordinate2DMake(newLat, newLng);
        const MKCoordinateSpan newSpan = MKCoordinateSpanMake(latDeltaBy2, lngDeltaBy2);
        
        QNode* newNode = [QNode nodeWithRegion:MKCoordinateRegionMake(newCenter, newSpan) filterController:_filterController];
        newNode.leadObject = leadObject;
        newNode.satellites = [satellites mutableCopy];
        newNode.count = 1 + satellites.count;
        
        *pNode = newNode;
        
        return YES;
    } else {
        NSAssert(!satellites, @"Satellites should be non-nil only when moving objects deeper");
        return [*pNode insertObject:leadObject];
    }
}

- (void) clearCachedClusters {
    self.cachedCluster = nil;
    [_upLeft clearCachedClusters];
    [_upRight clearCachedClusters];
    [_downLeft clearCachedClusters];
    [_downRight clearCachedClusters];
}

-(NSArray*)getObjectsInRegion:(MKCoordinateRegion)region minNonClusteredSpan:(CLLocationDegrees)span
{
    if( !MKCoordinateRegionIntersectsRegion(self.region, region) ) {
        return @[];
    }
    NSMutableArray* result = [NSMutableArray array];
    if( self.leadObject ) {
        if( MKCoordinateRegionContainsCoordinate(region, self.leadObject.coordinate) ) {
            [result addObject:self.leadObject];
            [result addObjectsFromArray:self.satellites.allObjects];
            return result;
        }
    } else if( MIN(self.region.span.latitudeDelta, self.region.span.longitudeDelta) >= span ) {
        [result addObjectsFromArray:[self.upLeft getObjectsInRegion:region minNonClusteredSpan:span]];
        [result addObjectsFromArray:[self.upRight getObjectsInRegion:region minNonClusteredSpan:span]];
        [result addObjectsFromArray:[self.downLeft getObjectsInRegion:region minNonClusteredSpan:span]];
        [result addObjectsFromArray:[self.downRight getObjectsInRegion:region minNonClusteredSpan:span]];
    } else {
        if( !self.cachedCluster ) {
            NSArray* allChildren = [self getObjectsInRegion:self.region minNonClusteredSpan:0];
            if (allChildren && allChildren.count > 0) {
                if (allChildren.count == 1) {
                    return @[allChildren.firstObject];
                } else {
                    self.cachedCluster = [_filterController newQClusterObjectWithChildren:allChildren];
                }
            }
        }
        if (_cachedCluster) {
            [result addObject:_cachedCluster];
        }
    }
    return result;
}

-(NSArray*)neighboursForLocation:(CLLocationCoordinate2D)location limitCount:(NSUInteger)limit
{
    NSArray* nodesPath = [self nodesPathForLocation:location];
    for( QNode* node in nodesPath.reverseObjectEnumerator ) {
        if( node.count < limit && node != [nodesPath firstObject] ) {
            continue;
        }
        const CLLocationDegrees latitudeDelta = 2 * (node.region.span.latitudeDelta / 2 - fabs(node.region.center.latitude - location.latitude));
        const CLLocationDegrees longitudeDelta = 2 * (node.region.span.longitudeDelta / 2 - fabs(node.region.center.longitude - location.longitude));
        const MKCoordinateSpan span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta);
        NSMutableArray* objects = [[self getObjectsInRegion:MKCoordinateRegionMake(location, span) minNonClusteredSpan:0] mutableCopy];
        if( objects.count < limit && node != [nodesPath firstObject] ) {
            continue;
        }
        [objects sortUsingComparator:^NSComparisonResult(id<QTreeInsertable> obj1, id<QTreeInsertable> obj2)
         {
             CLLocationDistance m1 = CLMetersBetweenCoordinates(obj1.coordinate, location);
             CLLocationDistance m2 = CLMetersBetweenCoordinates(obj2.coordinate, location);
             if( m1 < m2 ) {
                 return NSOrderedAscending;
             } else if( m1 > m2 ) {
                 return NSOrderedDescending;
             } else {
                 return NSOrderedSame;
             }
         }];
        return [objects subarrayWithRange:NSMakeRange(0, MIN(limit, objects.count))];
    }
    return @[];
}

-(NSArray*)nodesPathForLocation:(CLLocationCoordinate2D)location
{
    if( !MKCoordinateRegionContainsCoordinate(self.region, location) ) {
        return @[];
    }
    QNode* cur = self;
    NSMutableArray* result = [NSMutableArray arrayWithObject:cur];
    while( YES ) {
        if( cur.downRight && MKCoordinateRegionContainsCoordinate(cur.downRight.region, location) ) {
            [result addObject:cur.downRight];
            cur = cur.downRight;
        } else if( cur.downLeft && MKCoordinateRegionContainsCoordinate(cur.downLeft.region, location) ) {
            [result addObject:cur.downLeft];
            cur = cur.downLeft;
        } else if( cur.upRight && MKCoordinateRegionContainsCoordinate(cur.upRight.region, location) ) {
            [result addObject:cur.upRight];
            cur = cur.upRight;
        } else if( cur.upLeft && MKCoordinateRegionContainsCoordinate(cur.upLeft.region, location) ) {
            [result addObject:cur.upLeft];
            cur = cur.upLeft;
        } else {
            break;
        }
    }
    return result;
}

@end
